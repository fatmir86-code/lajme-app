import SwiftUI
import UIKit

// MARK: - Pull-to-Refresh via UIScrollView hosting

/// A ScrollView replacement that uses a real UIScrollView + UIRefreshControl under the hood.
/// This avoids the iOS 18 bug where .refreshable on SwiftUI ScrollView shows no spinner,
/// and avoids fragile view-hierarchy introspection that breaks across OS versions.
struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    let content: Content

    init(
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        RefreshableScrollViewRepresentable(onRefresh: onRefresh) {
            content
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - UIViewControllerRepresentable bridge

private struct RefreshableScrollViewRepresentable<Content: View>: UIViewControllerRepresentable {
    let onRefresh: () async -> Void
    let content: Content

    init(
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onRefresh = onRefresh
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRefresh: onRefresh)
    }

    func makeUIViewController(context: Context) -> ScrollViewController {
        let vc = ScrollViewController()

        // Attach refresh control
        let rc = UIRefreshControl()
        rc.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        vc.scrollView.refreshControl = rc

        // Host the SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        vc.hostContent(hostingController)

        context.coordinator.hostingController = hostingController

        return vc
    }

    func updateUIViewController(_ vc: ScrollViewController, context: Context) {
        // Update the SwiftUI content when state changes
        context.coordinator.hostingController?.rootView = content

        // After a layout pass, update content size
        DispatchQueue.main.async {
            vc.updateContentSize()
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject {
        let onRefresh: () async -> Void
        var hostingController: UIHostingController<Content>?

        init(onRefresh: @escaping () async -> Void) {
            self.onRefresh = onRefresh
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            Task { @MainActor in
                await onRefresh()
                sender.endRefreshing()
            }
        }
    }
}

// MARK: - UIViewController with UIScrollView

private final class ScrollViewController: UIViewController {
    let scrollView = UIScrollView()
    private var hostedView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func hostContent(_ hostingController: UIHostingController<some View>) {
        addChild(hostingController)
        let hosted = hostingController.view!
        hosted.backgroundColor = .clear
        hosted.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hosted)
        NSLayoutConstraint.activate([
            hosted.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosted.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            // Width must match the scroll view's frame, not content
            hosted.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        hostingController.didMove(toParent: self)
        hostedView = hosted
    }

    func updateContentSize() {
        guard let hosted = hostedView else { return }
        hosted.layoutIfNeeded()
        let size = hosted.systemLayoutSizeFitting(
            CGSize(width: scrollView.frame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if scrollView.contentSize.height != size.height {
            scrollView.contentSize = CGSize(width: scrollView.frame.width, height: size.height)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
    }
}

// MARK: - Convenience modifier (kept for API compatibility)

extension View {
    /// Wraps the view in a RefreshableScrollView. Use this ON a ScrollView's *content*,
    /// or replace your ScrollView entirely with RefreshableScrollView.
    func pullToRefresh(action: @escaping () async -> Void) -> some View {
        // This modifier is now a no-op marker; the actual RefreshableScrollView
        // is used directly in ArticleFeedView.
        self
    }
}
