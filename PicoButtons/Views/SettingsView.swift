import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section("Pico Buttons Pro") {
                Label(state.isPro ? "Pro is active — ads are removed." : "A one-time Pro purchase removes every ad.", systemImage: state.isPro ? "checkmark.seal.fill" : "sparkles")
                    .foregroundStyle(state.isPro ? .green : .primary)
                if !state.isPro {
                    Text("Make a one-time purchase to enjoy Pico Buttons without ads.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await state.purchasePro() }
                    } label: {
                        HStack {
                            Text(state.isProPurchaseInProgress ? "Purchasing…" : "Get Pico Buttons Pro")
                            Spacer()
                            if let product = state.proProduct {
                                Text(product.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(state.proProduct == nil || state.isProPurchaseInProgress)
                    Button("Restore purchases") { Task { await state.restoreProPurchases() } }
                }
            }
            Section("Privacy") {
                Link("Privacy Policy", destination: URL(string: "https://mailerdenight.github.io/pico-buttons-privacy/")!)
                Button("Privacy choices") { Task { await state.ads.presentPrivacyOptions() } }
                Link("Report an inappropriate ad", destination: URL(string: "https://support.google.com/google-ads/answer/7660847")!)
            }
            Section("About") {
                Text("APP_NAME_VERSION")
                Text("ABOUT_28_SOUNDS").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .alert("Pico Buttons Pro", isPresented: Binding(
            get: { state.proPurchaseError != nil },
            set: { if !$0 { state.proPurchaseError = nil } }
        )) {
            Button("OK", role: .cancel) { state.proPurchaseError = nil }
        } message: {
            Text(state.proPurchaseError ?? "")
        }
    }
}
