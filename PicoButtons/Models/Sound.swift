import Foundation

enum SoundCategory: String, CaseIterable, Identifiable, Codable {
    case reward, action, impact, system

    var id: String { rawValue }
    var localizationKey: String { "CATEGORY_\(rawValue.uppercased())" }
    var localizedName: String { NSLocalizedString(localizationKey, comment: "Sound category") }
}

struct Sound: Identifiable, Hashable, Codable {
    let id: String
    let resourceID: String
    let nameKey: String
    let icon: String
    let category: SoundCategory
    let pitch: Double
    let duration: Double

    var localizedName: String { NSLocalizedString(nameKey, comment: "Sound name") }
    /// Heartbeat is intentionally paced slowly before the user speed setting is applied.
    var tempoMultiplier: Float {
        switch nameKey {
        case "SOUND_ECG": 0.15
        case "SOUND_HEART": 0.25
        default: 1
        }
    }

    static let library: [Sound] = [
        sound(1, 1, "SOUND_FALL", "⬇️", .reward),
        sound(2, 2, "SOUND_STAR", "⭐️", .reward),
        sound(3, 3, "SOUND_JUMP", "🦘", .reward),
        sound(4, 4, "SOUND_PHONE", "☎️", .reward),
        sound(5, 6, "SOUND_GUN", "🔫", .reward),
        sound(6, 7, "SOUND_LASER", "🔆", .reward),
        sound(7, 8, "SOUND_NOTIFY", "🔔", .reward),

        sound(8, 9, "SOUND_CONNECT", "🔗", .action),
        sound(9, 10, "SOUND_MERGE", "🤝", .action),
        sound(10, 11, "SOUND_SHOT", "🎯", .action),
        sound(11, 12, "SOUND_ALIEN", "👽", .action),
        sound(12, 13, "SOUND_END", "🏁", .action),
        sound(13, 14, "SOUND_ALERT", "⚠️", .action),
        sound(14, 15, "SOUND_FREEZE", "🧊", .action),

        sound(15, 16, "SOUND_DAMAGE", "💥", .impact),
        sound(16, 17, "SOUND_DEPART", "🚂", .impact),
        sound(17, 18, "SOUND_HEAL", "❤️‍🩹", .impact),
        sound(18, 19, "SOUND_INFINITY", "♾️", .impact),
        sound(19, 20, "SOUND_ECG", "🫀", .impact),
        sound(20, 21, "SOUND_DOWN", "📉", .impact),
        sound(21, 22, "SOUND_COIN", "🪙", .impact),

        sound(22, 23, "SOUND_EMERGENCY", "🚨", .system),
        sound(23, 24, "SOUND_MOVE", "↔️", .system),
        sound(24, 25, "SOUND_DESTROY", "💣", .system),
        sound(25, 26, "SOUND_UFO", "🛸", .system),
        sound(26, 27, "SOUND_POWER", "⚡️", .system),
        sound(27, 28, "SOUND_HEART", "❤️", .system),
        sound(28, 29, "SOUND_BLESSING", "✨", .system)
    ]

    private static func sound(_ number: Int, _ resourceNumber: Int, _ nameKey: String, _ icon: String, _ category: SoundCategory) -> Sound {
        .init(id: String(format: "%02d", number), resourceID: String(format: "%02d", resourceNumber), nameKey: nameKey, icon: icon, category: category, pitch: 0, duration: 0)
    }
}
