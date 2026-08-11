import SwiftUI

struct AppRootView: View {
    @Environment(AppState.self) private var state
    @State private var isShowingSettings = false
    @State private var isShowingLibrary = false

    var body: some View {
        NavigationStack {
            BoardView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { isShowingLibrary = true } label: { Image(systemName: "square.grid.2x2") }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { isShowingSettings = true } label: { Image(systemName: "gearshape") }
                    }
                }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if state.adsEnabled { BannerAdView().frame(height: 50) }
        }
        .sheet(isPresented: $isShowingLibrary) { NavigationStack { LibraryView() } }
        .sheet(isPresented: $isShowingSettings, onDismiss: { state.considerAdBreak(.settingsClosed) }) { NavigationStack { SettingsView() } }
        .onChange(of: state.playback.activeSoundIDs) { _, activeSounds in
            if activeSounds.isEmpty { state.considerAdBreak(.playbackBreak) }
        }
        .preferredColorScheme(.dark)
        .task {
            await state.loadProEntitlement()
            if state.adsEnabled { await state.ads.start() }
        }
    }
}
