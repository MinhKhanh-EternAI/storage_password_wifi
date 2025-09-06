import SwiftUI

@main
struct WiFiOfflineApp: App {
    @StateObject private var store = WiFiStore()
    @StateObject private var current = CurrentWiFi()
    @AppStorage("theme") private var theme: AppTheme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(current)
                .preferredColorScheme(theme == .system ? nil : (theme == .light ? .light : .dark))
        }
    }
}
