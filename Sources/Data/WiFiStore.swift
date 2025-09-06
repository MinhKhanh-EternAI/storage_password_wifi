import Foundation
import Combine

final class WiFiStore: ObservableObject {
    @Published var items: [WiFiNetwork] = []
    @Published var editing: WiFiNetwork? = nil
    @Published var presentForm: Bool = false

    private let storageURL: URL = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("wifi_store.json")
    }()

    init() { load() }

    // MARK: CRUD
    func upsert(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
        persist()
    }

    func delete(_ item: WiFiNetwork) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    // MARK: Import/Export
    func replaceAll(with newItems: [WiFiNetwork]) {
        items = newItems
        persist()
    }

    func exportJSON() -> Data? {
        try? JSONEncoder().encode(items)
    }

    func importJSON(_ data: Data) {
        if let newItems = try? JSONDecoder().decode([WiFiNetwork].self, from: data) {
            replaceAll(with: newItems)
        }
    }

    // MARK: Persistence
    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        if let arr = try? JSONDecoder().decode([WiFiNetwork].self, from: data) {
            self.items = arr
        }
    }
}
