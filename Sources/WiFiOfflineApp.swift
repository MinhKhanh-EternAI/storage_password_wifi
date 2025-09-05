import SwiftUI

@main
struct WiFiOfflineApp: App {
    @StateObject private var store = WiFiStore.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
