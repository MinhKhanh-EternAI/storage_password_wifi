import Foundation
import Combine
import UniformTypeIdentifiers

final class WiFiStore: ObservableObject {
    // MARK: - State

    @Published var items: [WiFiNetwork] = [] {
        didSet { persistToDisk() }
    }

    @Published var currentSSID: String?

    @Published var allowLocalStorage: Bool = UserDefaults.standard.object(forKey: "allowLocalStorage") as? Bool ?? true
    @Published var allowICloudStorage: Bool = UserDefaults.standard.object(forKey: "allowICloudStorage") as? Bool ?? false

    private let legacyStorageKey = "WiFiStore.items.v1"
    private let firebase = FirebaseService()   // 🔗 Service kết nối Firestore

    // MARK: - Init

    init() {
        WiFiFileSystem.ensureDirectories()
        if !restoreFromDisk() {
            restoreFromUserDefaultsAndWriteToDisk()
        }
        sortInPlace()
    }

    // MARK: - Consent

    func setAllowLocalStorage(_ on: Bool) {
        allowLocalStorage = on
        UserDefaults.standard.set(on, forKey: "allowLocalStorage")
        persistToDisk()
    }

    func setAllowICloudStorage(_ on: Bool) {
        allowICloudStorage = on
        UserDefaults.standard.set(on, forKey: "allowICloudStorage")
        persistToDisk()
    }

    // Public reload (cho menu “Cập nhật”)
    func reloadFromDisk() {
        _ = restoreFromDisk()
        sortInPlace()
        objectWillChange.send()
    }

    // MARK: - CRUD

    /// Upsert ưu tiên theo BSSID (ghi đè record trùng BSSID, giữ id cũ). Nếu không có BSSID thì upsert theo id.
    func upsert(_ item: WiFiNetwork) {
        var newItem = item

        if let bssid = item.bssid?.lowercased(), !bssid.isEmpty {
            if let idx = items.firstIndex(where: { $0.bssid?.lowercased() == bssid }) {
                newItem.id = items[idx].id
                items[idx] = newItem
                sortInPlace()
                return
            }
        }

        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = newItem
        } else {
            items.append(newItem)
        }
        sortInPlace()
    }

    /// Thay toàn bộ danh sách (giữ lại cho trường hợp import toàn bộ)
    func replaceAll(with newItems: [WiFiNetwork]) {
        self.items = newItems
        sortInPlace()
        persistToDisk()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func sortInPlace() {
        items.sort { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending }
    }

    // MARK: - Persistence (File in Documents & iCloud)

    struct ExportFileV2: Codable {
        var schemaVersion: Int = 2
        var exportedAt: Date = Date()
        var items: [WiFiNetwork]
    }

    private func persistToDisk() {
        do {
            let data = try JSONEncoder.iso.encode(ExportFileV2(items: items))

            if allowLocalStorage {
                WiFiFileSystem.ensureDirectories()
                try data.write(to: WiFiFileSystem.localDatabaseFile, options: .atomic)
            }

            if allowICloudStorage, let icDB = WiFiFileSystem.iCloudDatabaseFile {
                try data.write(to: icDB, options: .atomic)
            }
        } catch {
            print("Persist error:", error.localizedDescription)
        }
    }

    /// Khôi phục từ Database/wifi-database.json (hoặc .js nếu bạn config vậy). Trả về true nếu đọc được.
    @discardableResult
    private func restoreFromDisk() -> Bool {
        do {
            let url = WiFiFileSystem.localDatabaseFile
            guard FileManager.default.fileExists(atPath: url.path) else { return false }
            let data = try Data(contentsOf: url)
            try decodeAndAssign(data: data)
            return true
        } catch {
            print("Restore error:", error.localizedDescription)
            return false
        }
    }

    /// Migrate dữ liệu cũ từ UserDefaults sang file
    private func restoreFromUserDefaultsAndWriteToDisk() {
        guard let data = UserDefaults.standard.data(forKey: legacyStorageKey) else { return }
        do {
            let old = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            self.items = old
            persistToDisk()
        } catch {
            print("Legacy restore error:", error.localizedDescription)
        }
    }

    // MARK: - Export snapshots (Export/)

    @discardableResult
    func exportSnapshot() throws -> URL {
        let fileName = WiFiFileSystem.makeTimestampedExportFileName()
        let localURL = WiFiFileSystem.localExportDir.appendingPathComponent(fileName)

        let payload = ExportFileV2(items: items)
        let data = try JSONEncoder.iso.encode(payload)

        WiFiFileSystem.ensureDirectories()
        try data.write(to: localURL, options: .atomic)

        if allowICloudStorage, let iCloudDir = WiFiFileSystem.iCloudExportDir {
            let icURL = iCloudDir.appendingPathComponent(fileName)
            try data.write(to: icURL, options: .atomic)
        }
        return localURL
    }

    // MARK: - Import (.json) + merge theo BSSID

    enum ImportError: Error { case invalidEncoding, invalidFormat, empty }

    func importFrom(url: URL) throws {
        let needs = url.startAccessingSecurityScopedResource()
        defer { if needs { url.stopAccessingSecurityScopedResource() } }

        var readErr: NSError?
        var data = Data()
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &readErr) { newURL in
            data = (try? Data(contentsOf: newURL)) ?? Data()
        }
        if let e = readErr { throw e }
        guard !data.isEmpty else { throw ImportError.empty }

        try decodeAndMerge(data: data)
        sortInPlace()
    }

    // MARK: - Decode helpers

    private struct WrapperAny: Codable { let items: [WiFiNetwork] }

    private func decodeAndAssign(data: Data) throws {
        let dec = JSONDecoder()
        if let v2 = try? dec.decode(ExportFileV2.self, from: data) { self.items = v2.items; return }
        if let wrap = try? dec.decode(WrapperAny.self, from: data) { self.items = wrap.items; return }
        self.items = try dec.decode([WiFiNetwork].self, from: data)
    }

    private func decodeAndMerge(data: Data) throws {
        let dec = JSONDecoder()
        var incoming: [WiFiNetwork]? = nil
        if let v2 = try? dec.decode(ExportFileV2.self, from: data) {
            incoming = v2.items
        } else if let wrap = try? dec.decode(WrapperAny.self, from: data) {
            incoming = wrap.items
        } else if let arr = try? dec.decode([WiFiNetwork].self, from: data) {
            incoming = arr
        }
        guard let list = incoming, !list.isEmpty else { throw ImportError.empty }
        mergeByBSSID(list)
    }

    /// Merge nhập theo BSSID (ghi đè trùng BSSID, thêm BSSID mới, bỏ qua record không có BSSID)
    private func mergeByBSSID(_ incoming: [WiFiNetwork]) {
        var indexByBSSID: [String: Int] = [:]
        for (i, it) in items.enumerated() {
            if let b = it.bssid?.lowercased(), !b.isEmpty { indexByBSSID[b] = i }
        }

        for var nw in incoming {
            guard let bss = nw.bssid?.lowercased(), !bss.isEmpty else { continue }
            if let idx = indexByBSSID[bss] {
                // giữ id cũ
                nw.id = items[idx].id
                items[idx] = nw
            } else {
                items.append(nw)
            }
        }
        persistToDisk()
    }

    // MARK: - Cloud Sync (Firestore)

    func syncToCloud() {
        firebase.syncUpload(from: self) { result in
            switch result {
            case .success:
                print("✅ Synced to Firestore")
            case .failure(let error):
                print("❌ Sync error:", error)
            }
        }
    }

    func restoreFromCloud() {
        firebase.fetchNetworks { result in
            switch result {
            case .success(let networks):
                DispatchQueue.main.async {
                    self.replaceAll(with: networks)
                }
            case .failure(let error):
                print("❌ Fetch error:", error)
            }
        }
    }
}

// MARK: - JSON helpers

private extension JSONEncoder {
    static var iso: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }
}
