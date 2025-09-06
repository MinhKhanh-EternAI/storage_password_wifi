import Foundation
import Combine

@MainActor
final class WiFiStore: ObservableObject {
    @Published private(set) var items: [WiFiNetwork] = []

    private let storageURL: URL = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("wifi_store.json")
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    // MARK: - CRUD
    func upsert(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
        save()
    }

    func update(_ item: WiFiNetwork) {
        upsert(item)
    }

    func add(_ newItem: WiFiNetwork) {
        upsert(newItem)
    }

    func replaceAll(with newItems: [WiFiNetwork]) {
        items = newItems
        save()
    }

    func delete(_ item: WiFiNetwork) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        if let arr = try? decoder.decode([WiFiNetwork].self, from: data) {
            self.items = arr
        }
    }

    // MARK: - Import / Export JSON
    /// Xuất dữ liệu hiện tại ra file JSON tạm để chia sẻ
    @discardableResult
    func exportJSON() throws -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "wifi_export_\(df.string(from: Date())).json"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let data = try encoder.encode(items)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Nhập dữ liệu từ file JSON. mode = .replace sẽ thay thế toàn bộ, .merge sẽ gộp theo SSID (tránh trùng).
    func importJSON(from url: URL, mode: ImportMode = .replace) throws {
        let data = try Data(contentsOf: url)
        let incoming = try decoder.decode([WiFiNetwork].self, from: data)
        switch mode {
        case .replace:
            replaceAll(with: incoming)
        case .merge:
            mergeBySSID(incoming)
        }
    }

    // Gộp theo SSID: item mới sẽ ghi đè item cũ cùng SSID
    private func mergeBySSID(_ newItems: [WiFiNetwork]) {
        var map: [String: WiFiNetwork] = [:]
        for item in items {
            map[item.ssid] = item
        }
        for newItem in newItems {
            map[newItem.ssid] = newItem
        }
        items = Array(map.values)
        // Sắp xếp cho dễ nhìn (tuỳ ý)
        items.sort { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending }
        save()
    }

    enum ImportMode {
        case replace
        case merge
    }
}
