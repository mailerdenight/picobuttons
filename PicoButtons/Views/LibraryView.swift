import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var state
    @State private var selectedCategory = SoundCategory.allCases[0]

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(SoundCategory.allCases) { category in
                        Text(category.localizedName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section(selectedCategory.localizedName) {
                ForEach(Sound.library.filter { $0.category == selectedCategory }) { sound in
                    Button {
                        state.play(sound)
                    } label: {
                        HStack {
                            Image(systemName: "waveform").foregroundStyle(.cyan)
                            Text(sound.localizedName)
                            Spacer()
                            Image(systemName: "play.fill").font(.caption)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedCategory) { _, _ in state.considerAdBreak(.categoryChanged) }
        .navigationTitle("28 Sounds")
    }
}
