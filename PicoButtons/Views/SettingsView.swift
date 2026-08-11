import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section("Pico Buttons Pro") {
                Label(state.isPro ? "Pro is active — ads are removed." : "A one-time Pro purchase removes every ad.", systemImage: state.isPro ? "checkmark.seal.fill" : "sparkles")
                    .foregroundStyle(state.isPro ? .green : .primary)
                if !state.isPro {
                    Text("Pro also includes extra sounds, favorites, rapid-tap mode, timer stop, volume limiting, and parent mode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button(state.isProPurchaseInProgress ? "Purchasing…" : "Get Pico Buttons Pro") {
                        Task { await state.purchasePro() }
                    }
                    .disabled(state.proProduct == nil || state.isProPurchaseInProgress)
                    Button("Restore purchases") { Task { await state.restoreProPurchases() } }
                }
            }
            Section("Privacy") {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Button("Privacy choices") { Task { await state.ads.presentPrivacyOptions() } }
            }
            Section("About") {
                Text("APP_NAME_VERSION")
                Text("ABOUT_28_SOUNDS").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
