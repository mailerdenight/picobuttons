import SwiftUI

enum BoardLayout: String, CaseIterable, Codable, Identifiable { case grid, columns; var id: String { rawValue } }
enum CaseTheme: String, CaseIterable, Codable, Identifiable { case midnight, sunset, mint; var id: String { rawValue }
    var colors: [Color] { switch self { case .midnight: [.black, Color(red: 0.08, green: 0.1, blue: 0.17)]; case .sunset: [Color(red: 0.24, green: 0.06, blue: 0.13), Color(red: 0.46, green: 0.14, blue: 0.14)]; case .mint: [Color(red: 0.02, green: 0.18, blue: 0.16), Color(red: 0.03, green: 0.29, blue: 0.24)] } }
}
struct BoardConfiguration: Codable, Equatable {
    var soundIDs = Sound.library.map(\.id)
    var layout: BoardLayout = .grid
    var theme: CaseTheme = .midnight
    var colors = ["FF5C5C", "FFB547", "E6E85C", "59D77E", "50C6E8", "678BFF", "B776EF", "F17AB5"]
    static let key = "boardConfiguration"
    static func load() -> BoardConfiguration { guard let data = UserDefaults.standard.data(forKey: key), let value = try? JSONDecoder().decode(BoardConfiguration.self, from: data) else { return .init() }; return value }
    func save() { if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.key) } }
}
