import Foundation
import Combine

/// Lưu JSON trong thư mục Documents/WiFiOffline/wifi.json
final class WiFiStore: ObservableObject {
    @Published private(set) var items: [WiFiNetwork] = []
    private let folderName = "WiFiOffline"
    private let fileName = "wifi.json"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        // Tự lưu mỗi khi dữ liệu đổi
        $items
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    // MARK: File URLs
    private var folderURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(folderName, isDirectory: true)
    }
    private var fileURL: URL { folderURL.appendingPathComponent(fileName) }

    // MARK: CRUD
    func add(_ item: WiFiNetwork) { items.insert(item, at: 0) }
    func update(_ item: WiFiNetwork) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            var v = item
            v.updatedAt = .init()
            items[i] = v
        }
    }
    func delete(at offsets: IndexSet) { items.remove(atOffsets: offsets) }
    func delete(_ id: UUID) { items.removeAll { $0.id == id } }

    // MARK: Persistence
    func load() {
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                items = []
                return
            }
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            items = decoded
        } catch {
            print("Load error:", error)
            items = []
        }
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try JSONEncoder.pretty.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save error:", error)
        }
    }

    // MARK: Import/Export
    func exportData() throws -> Data {
        try JSONEncoder.pretty.encode(items)
    }
    func importData(_ data: Data, merge: Bool) throws {
        let incoming = try JSONDecoder().decode([WiFiNetwork].self, from: data)
        if merge {
            // hợp nhất theo id, ssid
            var map = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            for n in incoming {
                if let existed = items.first(where: { $0.ssid == n.ssid }) {
                    map[existed.id] = n
                } else {
                    map[n.id] = n
                }
            }
            items = Array(map.values).sorted { $0.updatedAt > $1.updatedAt }
        } else {
            items = incoming
        }
    }
}

// MARK: Pretty JSON
fileprivate extension JSONEncoder {
    static var pretty: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
}
fileprivate extension JSONDecoder {
    convenience init(dateISO8601: Void = ()) {
        self.init()
        dateDecodingStrategy = .iso8601
    }
}
