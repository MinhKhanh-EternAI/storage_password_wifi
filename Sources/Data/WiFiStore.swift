import Foundation
import Combine

final class WiFiStore: ObservableObject {
    @Published private(set) var items: [WiFiNetwork] = []

    private let storageURL: URL = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("wifi_store.json")
    }()

    init() { load() }

    func upsert(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
        save()
    }

    func update(_ item: WiFiNetwork) { upsert(item) }

    func delete(_ item: WiFiNetwork) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch { print("Save error:", error) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        if let arr = try? JSONDecoder().decode([WiFiNetwork].self, from: data) {
            self.items = arr
        }
    }
}
