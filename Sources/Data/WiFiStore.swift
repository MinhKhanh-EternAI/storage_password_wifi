import Foundation

final class WiFiStore: ObservableObject {
    @Published var networks: [WiFiNetwork] = [] {
        didSet { save() }
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("wifi.json")
    }()

    init() { load() }

    func add(_ net: WiFiNetwork) { networks.insert(net, at: 0) }
    func update(_ net: WiFiNetwork) {
        guard let i = networks.firstIndex(where: { $0.id == net.id }) else { return }
        networks[i] = net
    }
    func delete(_ net: WiFiNetwork) {
        networks.removeAll { $0.id == net.id }
    }

    // MARK: Persistence
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let items = try? JSONDecoder().decode([WiFiNetwork].self, from: data) {
            self.networks = items
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(networks) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // Import / Export
    func importFromJSON(url: URL) {
        guard let data = try? Data(contentsOf: url),
              let arr = try? JSONDecoder().decode([WiFiNetwork].self, from: data) else { return }
        networks = arr + networks
    }

    func exportToTemp() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wifi-export.json")
        guard let data = try? JSONEncoder().encode(networks) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }
}
