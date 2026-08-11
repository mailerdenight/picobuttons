import SwiftUI
import UIKit

struct BoardView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.015, green: 0.018, blue: 0.022), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            RetroConsole()
                .padding(8)
                .frame(maxWidth: 440, maxHeight: .infinity)
        }
        .task { state.playback.warmUp(Sound.library) }
    }
}

private struct RetroConsole: View {
    var body: some View {
        GeometryReader { proxy in
            let padHeight = max(44, min(58, (proxy.size.height - 150) / 7))

            VStack(spacing: 6) {
                LCDPanel()
                    .frame(height: 72)

                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    ForEach(0..<7, id: \.self) { row in
                        GridRow {
                            ForEach(SoundCategory.allCases) { category in
                                let sound = Sound.library.filter { $0.category == category }[row]
                                SoundPad(sound: sound, height: padHeight)
                            }
                        }
                    }
                }
                .padding(6)
                .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.13), lineWidth: 1) }

                ControlsPanel()
                    .frame(height: 46)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background {
                ConsoleCase()
                    .overlay(CaseScrews().padding(10))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct LCDPanel: View {
    @Environment(AppState.self) private var state

    private var activeSound: Sound? {
        guard let id = state.lastPlayedSoundID, state.playback.activeSoundIDs.contains(id) else { return nil }
        return Sound.library.first { $0.id == id }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.055)], startPoint: .top, endPoint: .bottom))

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(red: 0.61, green: 0.66, blue: 0.43))
                .padding(7)
                .overlay { LCDScanlines().clipShape(RoundedRectangle(cornerRadius: 5)).padding(7) }

            if let sound = activeSound {
                PlayingLCD(sound: sound)
            } else {
                VStack(spacing: 3) {
                    Text("POCKET 8-BIT")
                        .font(.system(size: 21, weight: .black, design: .monospaced))
                    Text("28 SOUNDS — TAP TO PLAY")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .tracking(0.45)
                }
                .foregroundStyle(LCDInk)
            }
        }
        .overlay { RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.3), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(activeSound.map { String(format: NSLocalizedString("LCD playing %@", comment: ""), $0.localizedName) } ?? NSLocalizedString("POCKET 8-BIT", comment: ""))
    }
}

private struct PlayingLCD: View {
    @Environment(AppState.self) private var state
    let sound: Sound

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: NSLocalizedString("NO. %@", comment: ""), sound.id))
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                Text(sound.localizedName.uppercased())
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(String(format: NSLocalizedString("%@  •  PITCH %@", comment: ""), state.isLooping ? NSLocalizedString("LOOP", comment: "") : NSLocalizedString("ONE SHOT", comment: ""), state.pitchLabel))
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
            }
            Spacer(minLength: 0)
            PixelWaveform()
                .frame(width: 55, height: 35)
        }
        .padding(.horizontal, 14)
        .foregroundStyle(LCDInk)
    }
}

private struct PixelWaveform: View {
    private let heights: [CGFloat] = [9, 21, 14, 30, 18, 25, 11, 27, 15]
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(heights.enumerated()), id: \.offset) { _, height in
                Rectangle().fill(LCDInk).frame(width: 3, height: height)
            }
        }
    }
}

private struct SoundPad: View {
    @Environment(AppState.self) private var state
    let sound: Sound
    let height: CGFloat
    @State private var isPressed = false

    var body: some View {
        let color = RetroPalette.color(for: sound.category)
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(colors: [color.light, color.dark], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) { RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(0.7), lineWidth: 1) }
                .overlay { RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white, lineWidth: isPlaying ? 2 : 0) }
                .overlay(alignment: .bottom) { Capsule().fill(.black.opacity(0.25)).frame(height: 3).padding(.horizontal, 7).padding(.bottom, 4) }

            VStack(spacing: 1) {
                Text(sound.icon)
                    .font(.system(size: min(16, height * 0.3)))
                Text(sound.localizedName.uppercased())
                    .font(.system(size: min(8, height * 0.15), weight: .black, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .foregroundStyle(.black.opacity(0.68))
            .padding(.top, 6)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Text(sound.id)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(.black.opacity(0.58))
                .padding(5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .scaleEffect(isPressed ? 0.95 : 1)
        .offset(y: isPressed ? 2 : 0)
        .shadow(color: color.light.opacity(isPlaying || isPressed ? 0.95 : 0.25), radius: isPlaying || isPressed ? 10 : 2)
        .shadow(color: .black.opacity(0.85), radius: isPressed ? 1 : 2, y: isPressed ? 1 : 3)
        .animation(.easeOut(duration: 0.07), value: isPressed)
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressed else { return }
                isPressed = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.65)
                state.play(sound)
            }
            .onEnded { _ in isPressed = false }
        )
        .accessibilityElement()
        .accessibilityLabel(String(format: NSLocalizedString("Sound pad %@ %@", comment: ""), sound.id, sound.localizedName))
        .accessibilityValue(isPlaying ? NSLocalizedString("PLAYING", comment: "") : NSLocalizedString("READY", comment: ""))
        .accessibilityHint(state.isLooping ? NSLocalizedString("Loop replaces the current loop sound", comment: "") : NSLocalizedString("Plays immediately", comment: ""))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { state.play(sound) }
    }

    private var isPlaying: Bool { state.playback.activeSoundIDs.contains(sound.id) }
}

private struct ControlsPanel: View {
    @Environment(AppState.self) private var state
    var body: some View {
        HStack(spacing: 8) {
            LoopButton().frame(width: 70)
            PitchControl().frame(maxWidth: .infinity)
            StopButton().frame(width: 70)
        }
    }
}

private struct LoopButton: View {
    @Environment(AppState.self) private var state
    var body: some View {
        Button { state.toggleLoop() } label: {
            VStack(spacing: 1) {
                Image(systemName: "repeat").font(.system(size: 13, weight: .black))
                Text("LOOP").font(.system(size: 9, weight: .black, design: .monospaced))
            }
            .foregroundStyle(state.isLooping ? .white : .white.opacity(0.62))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(state.isLooping ? Color(hex: "9A3400") : Color(white: 0.1), in: RoundedRectangle(cornerRadius: 9))
            .overlay { RoundedRectangle(cornerRadius: 9).stroke(state.isLooping ? .orange : .white.opacity(0.17), lineWidth: 1) }
        }
        .buttonStyle(TactileButtonStyle())
        .accessibilityLabel("LOOP")
        .accessibilityValue(state.isLooping ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: ""))
        .accessibilityHint(NSLocalizedString("Repeats one selected sound", comment: ""))
    }
}

private struct PitchControl: View {
    @Environment(AppState.self) private var state
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Pitch.allCases) { pitch in
                Button { state.setPitch(pitch) } label: {
                    Text(LocalizedStringKey(pitch.rawValue))
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(state.pitch == pitch ? .black : .white.opacity(0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(state.pitch == pitch ? Color(hex: "B6D655") : .clear)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(format: NSLocalizedString("Pitch %@", comment: ""), NSLocalizedString(pitch.rawValue, comment: "")))
                .accessibilityAddTraits(state.pitch == pitch ? .isSelected : [])
            }
        }
        .padding(3)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 9))
        .overlay { RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.17), lineWidth: 1) }
        .accessibilityElement(children: .contain)
    }
}

private struct StopButton: View {
    @Environment(AppState.self) private var state
    var body: some View {
        Button { state.stopPlayback() } label: {
            VStack(spacing: 2) {
                Image(systemName: "stop.fill").font(.system(size: 12, weight: .black))
                Text("STOP").font(.system(size: 9, weight: .black, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(state.playback.activeSoundIDs.isEmpty ? 0.35 : 0.95))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "651018"), in: RoundedRectangle(cornerRadius: 9))
            .overlay { RoundedRectangle(cornerRadius: 9).stroke(.red.opacity(state.playback.activeSoundIDs.isEmpty ? 0.2 : 0.75), lineWidth: 1) }
        }
        .buttonStyle(TactileButtonStyle())
        .disabled(state.playback.activeSoundIDs.isEmpty)
        .accessibilityLabel("STOP")
        .accessibilityHint(NSLocalizedString("Stops every playing sound", comment: ""))
    }
}

private struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(color: .black.opacity(0.75), radius: configuration.isPressed ? 1 : 2, y: configuration.isPressed ? 1 : 3)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct ConsoleCase: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(LinearGradient(colors: [Color(white: 0.16), Color(white: 0.035), Color(white: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay { RoundedRectangle(cornerRadius: 30).stroke(LinearGradient(colors: [.white.opacity(0.52), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 2) }
            .shadow(color: .black.opacity(0.9), radius: 20, y: 10)
    }
}

private struct CaseScrews: View {
    var body: some View {
        VStack { HStack { CaseScrew(); Spacer(); CaseScrew() }; Spacer(); HStack { CaseScrew(); Spacer(); CaseScrew() } }
    }
}

private struct CaseScrew: View {
    var body: some View {
        Circle().fill(LinearGradient(colors: [Color(white: 0.4), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 6, height: 6).overlay { Rectangle().fill(.black.opacity(0.72)).frame(width: 3, height: 1) }
    }
}

private struct LCDScanlines: View {
    var body: some View {
        Canvas { context, size in
            for offset in stride(from: 1, through: size.height, by: 3) {
                var path = Path(); path.move(to: CGPoint(x: 0, y: offset)); path.addLine(to: CGPoint(x: size.width, y: offset))
                context.stroke(path, with: .color(LCDInk.opacity(0.12)), lineWidth: 1)
            }
        }
    }
}

private let LCDInk = Color(red: 0.16, green: 0.20, blue: 0.07)

private enum RetroPalette {
    static func color(for category: SoundCategory) -> (light: Color, dark: Color) {
        switch category {
        case .reward: (Color(hex: "F4DC34"), Color(hex: "9EBB24"))
        case .action: (Color(hex: "4FC8F5"), Color(hex: "167CCF"))
        case .impact: (Color(hex: "F65745"), Color(hex: "E87712"))
        case .system: (Color(hex: "B56BEF"), Color(hex: "ED62A5"))
        }
    }
}
