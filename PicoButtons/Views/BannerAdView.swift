import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdConfiguration.bannerUnitID
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate { }
}
#else
struct BannerAdView: View {
    var body: some View { EmptyView() }
}
#endif
