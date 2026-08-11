import Foundation
import Observation
import StoreKit
import UIKit

enum Pitch: String, CaseIterable, Identifiable {
    case low = "SLOW", mid = "MID", high = "FAST"

    var id: String { rawValue }
    var rate: Float {
        switch self {
        case .low: 0.75
        case .mid: 1
        case .high: 1.25
        }
    }
}

@MainActor
@Observable
final class AppState {
    var board: BoardConfiguration
    var lastPlayedSoundID: Sound.ID?
    var isLooping = true
    var pitch: Pitch = .mid
    var isShowingCustomizer = false
    var isShowingLibrary = false
    var isPro = false
    var proProduct: Product?
    var isProPurchaseInProgress = false

    let playback = PlaybackService()
    let ads: AdService

    init(ads: AdService = GoogleAdService()) {
        self.ads = ads
        self.board = BoardConfiguration.load()
    }

    var adsEnabled: Bool { !isPro }

    func loadProEntitlement() async {
        proProduct = try? await Product.products(for: [PurchaseConfiguration.proProductID]).first
        await refreshProEntitlement()
    }

    func purchasePro() async {
        guard let proProduct, !isProPurchaseInProgress else { return }
        isProPurchaseInProgress = true
        defer { isProPurchaseInProgress = false }
        guard case .success(let result) = try? await proProduct.purchase(),
              case .verified(let transaction) = result else { return }
        isPro = true
        await transaction.finish()
    }

    func restoreProPurchases() async {
        try? await AppStore.sync()
        await refreshProEntitlement()
    }

    func play(_ sound: Sound) {
        lastPlayedSoundID = sound.id
        if adsEnabled { ads.recordSoundTap() }
        playback.play(sound, repeating: isLooping)
    }

    func stopPlayback() {
        playback.stop()
    }

    func toggleLoop() {
        isLooping.toggle()
        playback.setLooping(isLooping)
    }

    var pitchLabel: String { NSLocalizedString(pitch.rawValue, comment: "Pitch setting") }

    func setPitch(_ pitch: Pitch) {
        self.pitch = pitch
        playback.setPlaybackRate(pitch.rate)
    }

    func considerAdBreak(_ breakPoint: AdBreak, from viewController: UIViewController? = nil) {
        guard adsEnabled else { return }
        ads.presentInterstitialIfEligible(
            for: breakPoint,
            isAudioPlaying: !playback.activeSoundIDs.isEmpty,
            from: viewController
        )
    }

    func saveBoard() { board.save() }

    private func refreshProEntitlement() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == PurchaseConfiguration.proProductID,
                  transaction.revocationDate == nil else { continue }
            isPro = true
            return
        }
        isPro = false
    }

}

enum PurchaseConfiguration {
    /// Create this non-consumable product in App Store Connect before release.
    static let proProductID = "com.atsushichiba.picobuttons.pro"
}
