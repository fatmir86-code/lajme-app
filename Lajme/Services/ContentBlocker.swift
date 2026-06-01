import Foundation
import WebKit

/// Singleton that compiles and caches WKContentRuleList for ad/tracker blocking
/// and provides WKUserScripts for cookie banner dismissal.
@MainActor
final class ContentBlocker {
    static let shared = ContentBlocker()

    private static let ruleListIdentifier = "lajme-content-blocker-v7"
    private var cachedRuleList: WKContentRuleList?

    private init() {}

    // MARK: - Public API

    /// Pre-compile rules at app launch. Call from ContentView.task {}
    func precompile() async {
        _ = await contentRuleList()
    }

    /// Returns the compiled content rule list, using cache when available.
    func contentRuleList() async -> WKContentRuleList? {
        if let cached = cachedRuleList {
            return cached
        }

        // Try disk cache (WebKit persists compiled bytecode)
        if let existing = await lookupExisting() {
            cachedRuleList = existing
            return existing
        }

        // Compile from JSON
        guard let compiled = await compileRules() else { return nil }
        cachedRuleList = compiled
        return compiled
    }

    /// WKUserScript that hides cookie consent banners via CSS (injected at document start)
    var cookieBannerCSSScript: WKUserScript {
        let css = Self.cookieBannerCSS.replacingOccurrences(of: "\n", with: " ")
        let js = """
        (function() {
            var style = document.createElement('style');
            style.textContent = '\(css)';
            (document.head || document.documentElement).appendChild(style);
        })();
        """
        return WKUserScript(
            source: js,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    /// WKUserScript that auto-clicks "Accept" buttons on cookie consent dialogs.
    /// Uses word-boundary regex patterns so we never accidentally click on
    /// "Continue Reading", "Close menu", "OK" on a paywall, or "I agree" on a
    /// Terms-of-Service dialog. Only triggers on explicit cookie-accept phrases.
    var cookieAutoAcceptScript: WKUserScript {
        let js = """
        (function() {
            // Patterns are anchored to the start of the trimmed button text.
            // Order doesn't matter — we test all and click the first match.
            var patterns = [
                /^accept\\s*all/i,            // "Accept All", "Accept all cookies"
                /^accept\\s+cookies/i,         // "Accept cookies"
                /^allow\\s+all\\s+cookies/i,
                /^i\\s+accept/i,               // "I Accept"
                /^agree\\s+and\\s+close/i,
                /^pranoj/i,                   // Albanian: Pranoj, Pranoj të gjitha, Pranoj cookies
                /^pranoni/i,                  // Albanian (formal): Pranoni
                /^pajtohem/i                  // Albanian: I agree (literal)
            ];

            function tryAccept() {
                var els = document.querySelectorAll(
                    'button, a, [role="button"], input[type="button"], input[type="submit"]'
                );
                for (var i = 0; i < els.length; i++) {
                    var el = els[i];
                    var text = (el.textContent || el.value || '').trim();
                    if (!text || text.length > 80) continue;
                    for (var j = 0; j < patterns.length; j++) {
                        if (!patterns[j].test(text)) continue;
                        var style = window.getComputedStyle(el);
                        if (style.display === 'none' || style.visibility === 'hidden') continue;
                        // Note: avoid el.offsetParent check — it returns null for
                        // `position: fixed` elements, which is exactly how cookie
                        // banners are typically positioned.
                        var rect = el.getBoundingClientRect();
                        if (rect.width === 0 || rect.height === 0) continue;
                        try { el.click(); return true; } catch (e) {}
                    }
                }
                return false;
            }

            // Try at multiple intervals — banners often appear after a delay
            setTimeout(tryAccept, 300);
            setTimeout(tryAccept, 1500);
            setTimeout(tryAccept, 4000);

            // Catch banners that appear after the timeouts (e.g., lazy-loaded)
            var obs = new MutationObserver(function() {
                if (tryAccept()) obs.disconnect();
            });
            obs.observe(document.documentElement, { childList: true, subtree: true });
            setTimeout(function() { obs.disconnect(); }, 12000);
        })();
        """
        return WKUserScript(
            source: js,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    // MARK: - Private

    private func lookupExisting() async -> WKContentRuleList? {
        await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().lookUpContentRuleList(
                forIdentifier: Self.ruleListIdentifier
            ) { ruleList, _ in
                continuation.resume(returning: ruleList)
            }
        }
    }

    private func compileRules() async -> WKContentRuleList? {
        let json = Self.contentBlockerJSON
        return await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: Self.ruleListIdentifier,
                encodedContentRuleList: json
            ) { ruleList, error in
                if let error {
                    print("[ContentBlocker] Compilation error: \(error.localizedDescription)")
                }
                continuation.resume(returning: ruleList)
            }
        }
    }

    // MARK: - Rules JSON

    private static let contentBlockerJSON: String = {
        let rules: [[String: Any]] = [
            // 1. Block all popups globally
            [
                "trigger": ["url-filter": ".*", "resource-type": ["popup"]],
                "action": ["type": "block"]
            ],

            // 2. Block ad networks (third-party only — preserves article images)
            // Google Ads
            blockThirdParty("doubleclick\\.net"),
            blockThirdParty("googlesyndication\\.com"),
            blockThirdParty("googleadservices\\.com"),
            blockThirdParty("adservice\\.google\\.com"),
            blockThirdParty("pagead2\\.googlesyndication\\.com"),
            blockThirdParty("google-analytics\\.com"),
            blockThirdParty("googletagmanager\\.com"),

            // Facebook / Meta
            blockThirdParty("connect\\.facebook\\.net"),
            blockThirdParty("facebook\\.com\\/tr"),
            blockThirdParty("fbcdn\\.net\\/.*\\/tr"),

            // Major ad networks
            blockThirdParty("amazon-adsystem\\.com"),
            blockThirdParty("media\\.net"),
            blockThirdParty("outbrain\\.com"),
            blockThirdParty("taboola\\.com"),
            blockThirdParty("criteo\\.com"),
            blockThirdParty("criteo\\.net"),
            blockThirdParty("ads-twitter\\.com"),
            blockThirdParty("adnxs\\.com"),
            blockThirdParty("adsrvr\\.org"),
            blockThirdParty("rubiconproject\\.com"),
            blockThirdParty("pubmatic\\.com"),
            blockThirdParty("openx\\.net"),
            blockThirdParty("bidswitch\\.net"),
            blockThirdParty("casalemedia\\.com"),
            blockThirdParty("sharethrough\\.com"),
            blockThirdParty("indexww\\.com"),
            blockThirdParty("33across\\.com"),
            blockThirdParty("smartadserver\\.com"),

            // Tracking / Analytics
            blockThirdParty("hotjar\\.com"),
            blockThirdParty("clarity\\.ms"),
            blockThirdParty("mouseflow\\.com"),
            blockThirdParty("quantserve\\.com"),
            blockThirdParty("scorecardresearch\\.com"),
            blockThirdParty("chartbeat\\.com"),

            // Push notification spam
            blockThirdParty("pushwoosh\\.com"),
            blockThirdParty("onesignal\\.com"),
            blockThirdParty("pushcrew\\.com"),
            blockThirdParty("subscribers\\.com"),

            // Scam / redirect networks
            blockThirdParty("aucey\\.com"),
            blockThirdParty("gfpxw\\.com"),
            blockThirdParty("olnoyep\\.com"),
            blockThirdParty("popads\\.net"),
            blockThirdParty("popcash\\.net"),
            blockThirdParty("propellerads\\.com"),
            blockThirdParty("revenuehits\\.com"),
            blockThirdParty("mgid\\.com"),
            blockThirdParty("revcontent\\.com"),

            // Balkan-specific ad networks
            blockThirdParty("adocean\\.pl"),
            blockThirdParty("gemius\\.pl"),

            // 3. First-party ad subdomains — many Albanian/Balkan sites
            // self-host their ad server on `ads.<sitename>.<tld>` so the
            // third-party filter above misses them. Block unconditionally.
            // Catches: ads.kallxo.com, ads.balkanweb.com, ads.gazetaexpress.com,
            // ads.telegrafi.com, ads.indeksonline.net, etc.
            blockAlways("^https?://ads\\."),

            // OpenX / Revive Adserver standard delivery paths, used by many
            // self-hosted ad servers (kallxo.com confirmed runs OpenX at
            // ads.kallxo.com/www/delivery/). Block the path regardless of host.
            blockAlways("/www/delivery/"),
            blockAlways("/openx/"),
            blockAlways("/revive/www/"),

            // 4. CSS hide ad containers — kept specific to avoid matching
            // legitimate elements ("ad-block" warnings, "addThis" iframes,
            // "Sponsored Content" badges that double as article tags, etc.)
            cssHide(".adsbygoogle"),
            cssHide("ins.adsbygoogle"),
            cssHide("[id^=\"google_ads\"]"),
            cssHide("[id^=\"div-gpt-ad\"]"),
            cssHide("[class*=\"ad-container\"]"),
            cssHide("[class*=\"ad-wrapper\"]"),
            cssHide("[class*=\"ad-banner\"]"),
            cssHide("[class*=\"ad-slot\"]"),
            cssHide("[id*=\"taboola\"]"),
            cssHide("[id*=\"outbrain\"]"),
            cssHide(".mgbox"),
            cssHide(".OUTBRAIN"),
            cssHide("iframe[src*=\"doubleclick\"]"),
            cssHide("iframe[src*=\"googlesyndication\"]"),
            cssHide("iframe[src*=\"googletag\"]"),
            cssHide("iframe[src*=\"facebook.com/tr\"]"),
            cssHide("[data-ad-slot]"),
            cssHide("[data-google-query-id]"),
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }()

    private static func blockThirdParty(_ urlFilter: String) -> [String: Any] {
        [
            "trigger": [
                "url-filter": urlFilter,
                "load-type": ["third-party"]
            ] as [String: Any],
            "action": ["type": "block"]
        ]
    }

    /// Block matching URLs unconditionally (first-party included). Use for
    /// self-hosted ad servers where the page-host == ad-host, which the
    /// third-party filter cannot catch.
    private static func blockAlways(_ urlFilter: String) -> [String: Any] {
        [
            "trigger": ["url-filter": urlFilter],
            "action": ["type": "block"]
        ]
    }

    private static func cssHide(_ selector: String) -> [String: Any] {
        [
            "trigger": ["url-filter": ".*"],
            "action": [
                "type": "css-display-none",
                "selector": selector
            ] as [String: Any]
        ]
    }

    /// WKUserScript that blocks ad-related JavaScript techniques without causing reload loops.
    /// Blocks document.write injection after load and ad-script patterns. We do NOT
    /// override `window.open` because legitimate Twitter/Facebook embeds use it to
    /// open tweets in new windows; the WKWebView config flag
    /// `javaScriptCanOpenWindowsAutomatically = false` plus our `createWebViewWith`
    /// returning nil already block ad popups at the native layer.
    var redirectBlockerScript: WKUserScript {
        let js = """
        (function() {
            // Block document.write after initial load (ad injection technique)
            var loaded = false;
            var origWrite = document.write;
            var origWriteln = document.writeln;
            document.addEventListener('DOMContentLoaded', function() {
                loaded = true;
            });
            document.write = function(html) {
                if (loaded) return;
                origWrite.call(document, html);
            };
            document.writeln = function(html) {
                if (loaded) return;
                origWriteln.call(document, html);
            };

            // Neuter common ad loader functions
            window.__google_ad_loaded = true;
            window.adsbygoogle = window.adsbygoogle || [];
            window.adsbygoogle.loaded = true;
        })();
        """
        return WKUserScript(
            source: js,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    /// WKUserScript that removes ad elements once after page load (no MutationObserver)
    var adRemovalScript: WKUserScript {
        let js = """
        (function() {
            function removeAds() {
                var selectors = [
                    'ins.adsbygoogle', '[id^="div-gpt-ad"]', '[id^="google_ads"]',
                    '[class*="ad-container"]', '[class*="ad-wrapper"]', '[class*="ad-banner"]',
                    '[class*="advertisement"]', '[id*="taboola"]', '[id*="outbrain"]',
                    'iframe[src*="doubleclick"]', 'iframe[src*="googlesyndication"]',
                    'iframe[src*="facebook.com/tr"]'
                ];
                var all = document.querySelectorAll(selectors.join(','));
                for (var i = 0; i < all.length; i++) {
                    all[i].remove();
                }
            }
            // Run once after load, and once more after 2 seconds for late-loading ads
            removeAds();
            setTimeout(removeAds, 2000);
        })();
        """
        return WKUserScript(
            source: js,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    // MARK: - Cookie Banner CSS

    private static let cookieBannerCSS = """
    #onetrust-banner-sdk, #onetrust-consent-sdk,
    .cc-banner, .cc-window, .cc-overlay,
    #cookie-consent, .cookie-banner, .cookie-notice,
    #cookie-notice, .cookie-popup, #cookie-popup,
    [class*="cookie-consent"], [id*="cookie-consent"],
    [class*="CookieConsent"], #CookieConsent,
    .gdpr-banner, #gdpr-banner, .gdpr-consent,
    .qc-cmp-ui-container, #qc-cmp2-container,
    [id*="sp_message"], .sp_message_container,
    .evidon-banner, #truste-consent-track,
    [class*="consent-banner"], [id*="consent-banner"],
    [class*="consent-overlay"], [id*="consent-overlay"],
    .fc-consent-root, .fc-dialog-overlay,
    #cookiescript_injected, .cookiescript_close,
    .privacy-banner, #privacy-banner,
    [class*="cookie"][class*="overlay"],
    [class*="cookie"][class*="modal"],
    [class*="privacy"][class*="banner"],
    [class*="gdpr"][class*="banner"],
    [id*="didomi"], .didomi-popup, .didomi-notice,
    [class*="didomi"], #didomi-host,
    [id*="Didomi"], .Didomi-popup,
    [class*="politika-e-cookie"], [class*="cookie-policy"],
    .cmp-container, #cmp-container,
    [class*="cmp-"], [id*="cmp-"],
    .truendo, #truendo,
    [class*="consent-manager"], [id*="consent-manager"] {
        display: none !important;
        visibility: hidden !important;
        opacity: 0 !important;
        pointer-events: none !important;
        height: 0 !important;
        overflow: hidden !important;
    }
    body.cookie-consent-active,
    body.modal-open,
    html.cookie-consent-active {
        overflow: auto !important;
        position: static !important;
    }
    """
}
