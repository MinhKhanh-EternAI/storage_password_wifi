import Foundation
import Combine
import UniformTypeIdentifiers

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

    // MARK: - Persistence
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

    // MARK: - Export / Import
    func exportData() -> Data? {
        try? JSONEncoder().encode(items)
    }

    func importData(_ data: Data, merge: Bool = true) throws {
        let incoming = try JSONDecoder().decode([WiFiNetwork].self, from: data)
        if merge {
            var map = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            for it in incoming { map[it.id] = it }
            items = Array(map.values)
        } else {
            items = incoming
        }
        save()
    }

    func tempExportURL() -> URL? {
        guard let data = exportData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wifi_export.json")
        try? data.write(to: url, options: .atomic)
        return url
    }
}
