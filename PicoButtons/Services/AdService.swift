import Foundation
import UIKit

/// Events that are deliberately separated from a sound-pad tap.
enum AdBreak: Sendable {
    case settingsClosed
    case categoryChanged
    case playbackBreak
}

/// Keeps full-screen ads away from the immediate sound-playing interaction.
@MainActor
final class InterstitialPolicy {
    private enum Key {
        static let firstLaunch = "ad.firstLaunch"
        static let lastPresentation = "ad.lastInterstitialPresentation"
    }

    private let defaults: UserDefaults
    private(set) var playsSinceLastAd = 0
    private var lastTapAt: Date?

    // Intentionally conservative for a sound toy used by children.
    private let launchGrace: TimeInterval = 120
    private let minimumInterval: TimeInterval = 8 * 60
    private let tapGrace: TimeInterval = 5
    private let minimumPlays = 40

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.firstLaunch) == nil {
            defaults.set(Date.now, forKey: Key.firstLaunch)
        }
    }

    func recordSoundTap() {
        lastTapAt = .now
        playsSinceLastAd += 1
    }

    func mayPresent(isAudioPlaying: Bool, now: Date = .now) -> Bool {
        guard !isAudioPlaying, playsSinceLastAd >= minimumPlays else { return false }
        guard let firstLaunch = defaults.object(forKey: Key.firstLaunch) as? Date,
              now.timeIntervalSince(firstLaunch) >= launchGrace else { return false }
        if let lastPresentation = defaults.object(forKey: Key.lastPresentation) as? Date,
           now.timeIntervalSince(lastPresentation) < minimumInterval { return false }
        if let lastTapAt, now.timeIntervalSince(lastTapAt) < tapGrace { return false }
        return true
    }

    func recordPresentation(at date: Date = .now) {
        defaults.set(date, forKey: Key.lastPresentation)
        playsSinceLastAd = 0
    }
}

@MainActor
protocol AdService: AnyObject {
    func start() async
    func recordSoundTap()
    func presentInterstitialIfEligible(for breakPoint: AdBreak, isAudioPlaying: Bool, from viewController: UIViewController?)
    func presentPrivacyOptions() async
}

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
import GoogleMobileAds
import UserMessagingPlatform

/// AdMob adapter. It supports only banners and carefully throttled interstitials.
@MainActor
final class GoogleAdService: NSObject, AdService, FullScreenContentDelegate {
    private let policy = InterstitialPolicy()
    private var interstitial: InterstitialAd?
    private var started = false

    func start() async {
        guard !started else { return }
        await requestConsentIfNeeded()
        guard ConsentInformation.shared.canRequestAds else { return }

        let configuration = MobileAds.shared.requestConfiguration
        // Google Mobile Ads 12 uses this COPPA-compatible setting. Move to
        // `ageRestrictedTreatment = .child` when the project adopts SDK 13.
        configuration.tagForChildDirectedTreatment = true
        configuration.maxAdContentRating = .general
        configuration.publisherPrivacyPersonalizationState = .disabled
        await MobileAds.shared.start()
        started = true
        await loadInterstitial()
    }

    func recordSoundTap() {
        policy.recordSoundTap()
    }

    func presentInterstitialIfEligible(for breakPoint: AdBreak, isAudioPlaying: Bool, from viewController: UIViewController?) {
        guard started,
              policy.mayPresent(isAudioPlaying: isAudioPlaying),
              let interstitial else { return }
        // The caller only invokes this at a navigation or playback break; never on a pad tap.
        interstitial.present(from: viewController)
        policy.recordPresentation()
        self.interstitial = nil
    }

    func presentPrivacyOptions() async {
        try? await ConsentForm.presentPrivacyOptionsForm(from: nil)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { await loadInterstitial() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitial = nil
        Task { await loadInterstitial() }
    }

    private func loadInterstitial() async {
        guard started, interstitial == nil else { return }
        interstitial = try? await InterstitialAd.load(with: AdConfiguration.interstitialUnitID, request: Request())
        interstitial?.fullScreenContentDelegate = self
    }

    private func requestConsentIfNeeded() async {
        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { _ in continuation.resume() }
        }
        try? await ConsentForm.loadAndPresentIfRequired(from: nil)
    }
}
#else
/// Lets the app compile and run without advertising SDK packages.
@MainActor
final class GoogleAdService: AdService {
    func start() async { }
    func recordSoundTap() { }
    func presentInterstitialIfEligible(for breakPoint: AdBreak, isAudioPlaying: Bool, from viewController: UIViewController?) { }
    func presentPrivacyOptions() async { }
}
#endif

enum AdConfiguration {
    /// Google test IDs only. Replace both IDs from AdMob before submitting the app.
    static let bannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
}
