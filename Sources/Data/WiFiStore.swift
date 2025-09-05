import Foundation

@MainActor
final class WiFiStore: ObservableObject {
    static let shared = WiFiStore()

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
        if let arr = try? JSONDecoder().decode([WiFiNetwork].self, from: data) {
            self.items = arr
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url)
        }
    }

    func add(_ item: WiFiNetwork) {
        items.append(item)
        save()
    }

    func update(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            save()
        }
    }

    func delete(_ indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
        save()
    }
}
