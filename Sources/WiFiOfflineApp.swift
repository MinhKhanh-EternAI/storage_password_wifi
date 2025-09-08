import SwiftUI
import FirebaseCore

@main
struct WiFiOfflineApp: App {
    @StateObject private var store = WiFiStore()
    @StateObject private var theme = ThemeManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(theme)
                .preferredColorScheme(theme.overrideColorScheme)
        }
    }
}
