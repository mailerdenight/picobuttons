import SwiftUI

@main
struct PicoButtonsApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .task { await appState.observeTransactions() }
        }
    }
}
