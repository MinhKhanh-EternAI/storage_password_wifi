import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var name: String {
        switch self {
        case .system: return "Hệ thống"
        case .light:  return "Sáng"
        case .dark:   return "Tối"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// Icon hiển thị trên thanh trên cùng: ☀️ nếu sáng, 🌙 nếu tối (Hệ thống thì theo theme hiện tại)
struct ThemeIcon: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.colorScheme) private var scheme

    private var iconName: String {
        switch themeMode {
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .system: return scheme == .dark ? "moon.fill" : "sun.max.fill"
        }
    }

    var body: some View {
        Image(systemName: iconName)
            .imageScale(.large)
            .font(.system(size: 18, weight: .semibold))
            .accessibilityLabel(Text("Chủ đề"))
    }
}

/// Nút chọn chủ đề: menu chỉ có chữ, **không icon** bên trong
struct ThemePickerButton: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system

    var body: some View {
        Menu {
            Picker("", selection: $themeMode) {
                ForEach(ThemeMode.allCases) { m in
                    Text(m.name).tag(m)
                }
            }
        } label: {
            ThemeIcon()
        }
    }
}
