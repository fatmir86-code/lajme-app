import SwiftUI
import WebKit

struct ArticleWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var estimatedProgress: Double = 0
    @State private var isLoading = true
    @State private var currentURL: URL?
    @State private var canGoBack = false
    @State private var webViewStore = WebViewStore()

    var displayDomain: String {
        (currentURL ?? url).host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }

                if canGoBack {
                    Button {
                        webViewStore.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                }

                Spacer()

                Text(displayDomain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(.secondaryLabel))
                    .lineLimit(1)

                Spacer()

                Button {
                    guard let shareURL = currentURL ?? Optional(url) else { return }
                    webViewStore.shareURL = shareURL
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }

                Button {
                    UIApplication.shared.open(currentURL ?? url)
                } label: {
                    Image(systemName: "safari")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            // Progress bar
            if isLoading {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: geometry.size.width * estimatedProgress, height: 2)
                        .animation(.linear(duration: 0.2), value: estimatedProgress)
                }
                .frame(height: 2)
            } else {
                Color.clear.frame(height: 2)
            }

            // Web content
            WebViewContainer(
                url: url,
                store: webViewStore,
                estimatedProgress: $estimatedProgress,
                isLoading: $isLoading,
                currentURL: $currentURL,
                canGoBack: $canGoBack
            )
        }
        .background(Color(.systemBackground))
        .sheet(item: $webViewStore.shareURL) { shareURL in
            ShareSheetView(items: [shareURL])
        }
        .onDisappear {
            webViewStore.cleanup()
        }
    }
}

// MARK: - Share URL wrapper

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Simple share sheet

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - WebView Store (holds the WKWebView instance)

@Observable
final class WebViewStore {
    var shareURL: URL?
    private var webView: WKWebView?

    func setWebView(_ wv: WKWebView) {
        webView = wv
    }

    func goBack() {
        webView?.goBack()
    }

    func cleanup() {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
    }
}

// MARK: - WKWebView UIViewRepresentable

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    let store: WebViewStore
    @Binding var estimatedProgress: Double
    @Binding var isLoading: Bool
    @Binding var currentURL: URL?
    @Binding var canGoBack: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Disable popup windows
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Add content blocking scripts (minimal — avoid DOM changes that cause flickering)
        let userContent = config.userContentController
        userContent.addUserScript(ContentBlocker.shared.redirectBlockerScript)
        userContent.addUserScript(ContentBlocker.shared.cookieAutoAcceptScript)

        // Create web view
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground

        // Store reference
        store.setWebView(webView)

        // Add KVO observers
        context.coordinator.observe(webView)

        // Load content rules async, then load URL
        Task { @MainActor in
            if let ruleList = await ContentBlocker.shared.contentRuleList() {
                config.userContentController.add(ruleList)
            }
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed — URL loaded once in makeUIView
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.removeObservers()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebViewContainer
        /// True once the first article page has finished loading.
        /// Gates the ad-redirect blocker so legitimate first-load redirects
        /// (HTTPS upgrade, www-stripping, trailing slash, AMP, etc.) are
        /// allowed through. After this flips true, non-user main-frame
        /// navigations are treated as ad redirects.
        private var initialLoadComplete = false
        private var progressObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var canGoBackObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?

        init(parent: WebViewContainer) {
            self.parent = parent
        }

        func observe(_ webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress) { [weak self] wv, _ in
                Task { @MainActor in
                    self?.parent.estimatedProgress = wv.estimatedProgress
                }
            }
            urlObservation = webView.observe(\.url) { [weak self] wv, _ in
                Task { @MainActor in
                    self?.parent.currentURL = wv.url
                }
            }
            canGoBackObservation = webView.observe(\.canGoBack) { [weak self] wv, _ in
                Task { @MainActor in
                    self?.parent.canGoBack = wv.canGoBack
                }
            }
            loadingObservation = webView.observe(\.isLoading) { [weak self] wv, _ in
                Task { @MainActor in
                    self?.parent.isLoading = wv.isLoading
                }
            }
        }

        func removeObservers() {
            progressObservation?.invalidate()
            urlObservation?.invalidate()
            canGoBackObservation?.invalidate()
            loadingObservation?.invalidate()
            progressObservation = nil
            urlObservation = nil
            canGoBackObservation = nil
            loadingObservation = nil
        }

        // MARK: - WKNavigationDelegate

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = requestURL.scheme?.lowercased() ?? ""

            // Open external schemes in system handler
            if ["tel", "mailto", "itms-apps", "itms-appss", "app-settings"].contains(scheme) {
                UIApplication.shared.open(requestURL)
                decisionHandler(.cancel)
                return
            }

            // Block non-http schemes (javascript:, data: for ads, etc.)
            if !["http", "https", "about"].contains(scheme) {
                decisionHandler(.cancel)
                return
            }

            // Block known scam/redirect domains as secondary defense.
            // Use exact-host match (and subdomain match) — not substring — so
            // legit hosts that happen to contain these strings aren't blocked.
            let host = requestURL.host?.lowercased() ?? ""
            let scamDomains = ["aucey.com", "gfpxw.com", "olnoyep.com", "popads.net",
                               "popcash.net", "propellerads.com",
                               "revcontent.com", "revenuehits.com"]
            if scamDomains.contains(where: { host == $0 || host.hasSuffix(".\($0)") }) {
                decisionHandler(.cancel)
                return
            }

            let isMainFrame = navigationAction.targetFrame?.isMainFrame == true
            let isUserClick = navigationAction.navigationType == .linkActivated

            // Allow all user-initiated navigation. Only `.other` (programmatic
            // JS-driven navigation) is treated as an ad redirect.
            let userInitiated: Bool
            switch navigationAction.navigationType {
            case .linkActivated, .backForward, .reload, .formSubmitted, .formResubmitted:
                userInitiated = true
            case .other:
                userInitiated = false
            @unknown default:
                userInitiated = true  // fail open for forward-compatibility
            }

            // Block ad redirects ONLY after the initial page load completes.
            // During the first load, allow ALL main-frame navigations — sites
            // legitimately redirect via HTTPS upgrade, www-stripping, trailing
            // slash, AMP versions, etc. Blocking those breaks article opening.
            if isMainFrame && initialLoadComplete && !userInitiated {
                #if DEBUG
                print("[AdBlock] Blocked post-load redirect: \(requestURL.absoluteString)")
                #endif
                decisionHandler(.cancel)
                return
            }

            // Handle new-window links (target="_blank")
            if navigationAction.targetFrame == nil {
                // Only load if user clicked it
                if isUserClick {
                    webView.load(URLRequest(url: requestURL))
                }
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        /// Mark the first successful page load. After this point, the redirect
        /// blocker becomes active and stops non-user main-frame navigations.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if !initialLoadComplete {
                initialLoadComplete = true
            }
        }

        // MARK: - WKUIDelegate

        /// Silently dismiss JS `alert()` calls. Without this stub, a site
        /// invoking `alert()` will crash WKWebView with an unhandled selector.
        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            completionHandler()
        }

        /// Silently decline JS `confirm()` calls. Treating as "cancel" prevents
        /// auto-progression through paywall/age-gate dialogs.
        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(false)
        }

        /// Silently decline JS `prompt()` calls.
        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            completionHandler(nil)
        }

        /// Block popup windows — do NOT load their URL
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            #if DEBUG
            print("[AdBlock] Blocked popup window: \(navigationAction.request.url?.absoluteString ?? "nil")")
            #endif
            return nil
        }
    }
}
