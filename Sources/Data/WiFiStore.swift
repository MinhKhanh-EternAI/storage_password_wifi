import Foundation

final class WiFiStore: ObservableObject {
    @Published var items: [WiFiNetwork] = []

    private let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("wifi.json")
    }()

    init() {
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([WiFiNetwork].self, from: data) {
            self.items = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func add(_ item: WiFiNetwork) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            save()
        }
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    // Import/Export toàn bộ
    func exportData() throws -> Data { try JSONEncoder().encode(items) }
    func importData(_ data: Data, merge: Bool) throws {
        let incoming = try JSONDecoder().decode([WiFiNetwork].self, from: data)
        if merge {
            // merge theo ssid + security
            var map = Dictionary(uniqueKeysWithValues: items.map { ($0.ssid + $0.security.rawValue, $0) })
            for it in incoming { map[it.ssid + it.security.rawValue] = it }
            items = Array(map.values).sorted { $0.ssid.lowercased() < $1.ssid.lowercased() }
        } else {
            items = incoming
        }
        save()
    }
}
