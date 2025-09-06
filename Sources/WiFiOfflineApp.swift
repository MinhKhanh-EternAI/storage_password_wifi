import SwiftUI

@main
struct WiFiOfflineApp: App {
    @StateObject private var store = WiFiStore()
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(themeMode.colorScheme)
        }
    }
}
