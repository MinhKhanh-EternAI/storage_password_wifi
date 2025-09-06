import Foundation
import Combine

final class WiFiStore: ObservableObject {
    @Published var items: [WiFiNetwork] = [] {
        didSet { persist() }
    }

    @Published var currentSSID: String? // “Wifi Hiện tại”
    private let storageKey = "WiFiStore.items.v1"

    init() {
        restore()
    }

    // MARK: - CRUD

    func upsert(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
        sortInPlace()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func sortInPlace() {
        items.sort { lhs, rhs in
            lhs.ssid.localizedCaseInsensitiveCompare(rhs.ssid) == .orderedAscending
        }
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Persist error: \(error)")
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            items = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            sortInPlace()
        } catch {
            print("Restore error: \(error)")
        }
    }
}
