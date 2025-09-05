import SwiftUI

/// Lưu & điều khiển giao diện sáng/tối bằng AppStorage
final class AppTheme: ObservableObject {
    @AppStorage("app_appearance") private var appearanceRaw: String = "system"
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String {
            switch self {
            case .system: return "Hệ thống"
            case .light:  return "Sáng"
            case .dark:   return "Tối"
            }
        }
    }
    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue; objectWillChange.send() }
    }
}
