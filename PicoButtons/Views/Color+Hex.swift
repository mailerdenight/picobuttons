import SwiftUI

extension Color { init(hex: String) { let value = UInt64(hex, radix: 16) ?? 0; self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255) } }

extension UIApplication { var topViewController: UIViewController? { guard let scene = connectedScenes.compactMap({ $0 as? UIWindowScene }).first, let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }; return root.presentedViewController ?? root } }
