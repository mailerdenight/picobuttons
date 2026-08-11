import SwiftUI

struct CustomizeView: View {
    @Environment(AppState.self) private var state
    @State private var selectedSlot = 0
    var body: some View {
        @Bindable var state = state
        Form {
            Section("Button assignment") { Picker("Slot", selection: $selectedSlot) { ForEach(0..<8, id: \.self) { Text("Button \($0 + 1)").tag($0) } }; Picker("Sound", selection: $state.board.soundIDs[selectedSlot]) { ForEach(Sound.library) { Text($0.localizedName).tag($0.id) } }.onChange(of: state.board) { _, _ in state.saveBoard() } }
            Section("Layout") { Picker("Layout", selection: $state.board.layout) { Text("4 × 2").tag(BoardLayout.grid); Text("2 × 4").tag(BoardLayout.columns) }.pickerStyle(.segmented) }
            Section("Button colors") { LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) { ForEach(0..<8, id: \.self) { index in Color(hex: state.board.colors[index]).frame(height: 34).clipShape(Circle()).overlay { if index == selectedSlot { Circle().stroke(.white, lineWidth: 3) } }.onTapGesture { state.board.colors.swapAt(selectedSlot, index); state.saveBoard() } } } }
            Section("Case theme") { ForEach(CaseTheme.allCases) { theme in ThemeRow(theme: theme) } }
        }.navigationTitle("Customize")
    }
}
private struct ThemeRow: View { @Environment(AppState.self) private var state; let theme: CaseTheme; var body: some View { Button { state.board.theme = theme; state.saveBoard() } label: { HStack { RoundedRectangle(cornerRadius: 8).fill(LinearGradient(colors: theme.colors, startPoint: .top, endPoint: .bottom)).frame(width: 44, height: 32); Text(theme.rawValue.capitalized); Spacer(); if state.board.theme == theme { Image(systemName: "checkmark.circle.fill") } } } } }
