import Foundation
import Combine
import UniformTypeIdentifiers

final class WiFiStore: ObservableObject {
    // MARK: - State

    @Published var items: [WiFiNetwork] = [] {
        didSet { persistToDisk() }
    }

    /// SSID đang kết nối (hiển thị ở "Mạng hiện tại")
    @Published var currentSSID: String?

    /// Người dùng đồng ý lưu trong "Trên iPhone"
    @Published var allowLocalStorage: Bool = UserDefaults.standard.object(forKey: "allowLocalStorage") as? Bool ?? true
    /// Người dùng đồng ý lưu/sao lưu lên iCloud Drive
    @Published var allowICloudStorage: Bool = UserDefaults.standard.object(forKey: "allowICloudStorage") as? Bool ?? false

    // Backup key cũ (migrate từ UserDefaults nếu có)
    private let legacyStorageKey = "WiFiStore.items.v1"

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

    // MARK: - Public reload (cho nút "Cập nhật")

    /// Đọc lại database từ file (Documents/Database/wifi-database.json).
    func reloadFromDisk() {
        _ = restoreFromDisk()
        sortInPlace()
        objectWillChange.send()
    }

    // MARK: - CRUD

    /// Ghi đè theo BSSID nếu có (case-insensitive); nếu không có BSSID thì upsert theo id.
    func upsert(_ item: WiFiNetwork) {
        var newItem = item

        if let bssid = item.bssid?.lowercased(), !bssid.isEmpty {
            if let idx = items.firstIndex(where: { $0.bssid?.lowercased() == bssid }) {
                // Overwrite record trùng BSSID, giữ id cũ
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

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func sortInPlace() {
        items.sort { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending }
    }

    // MARK: - Persistence (File in Documents & iCloud)

    private func persistToDisk() {
        do {
            let data = try JSONEncoder.iso.encode(ExportFileV2(items: items))

            if allowLocalStorage {
                try WiFiFileSystem.ensureDirectories()
                try data.write(to: WiFiFileSystem.localDatabaseFile, options: .atomic)
            }

            if allowICloudStorage, let icDB = WiFiFileSystem.iCloudDatabaseFile {
                try data.write(to: icDB, options: .atomic)
            }
        } catch {
            print("Persist error:", error.localizedDescription)
        }
    }

    /// Khôi phục từ Database/wifi-database.json (local). Trả về true nếu đọc được.
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

    struct ExportFileV2: Codable {
        let schemaVersion: Int = 2
        let exportedAt: Date = .now
        var items: [WiFiNetwork]
    }

    @discardableResult
    func exportSnapshot() throws -> URL {
        let fileName = WiFiFileSystem.makeTimestampedExportFileName()
        let localURL = WiFiFileSystem.localExportDir.appendingPathComponent(fileName)

        let payload = ExportFileV2(items: items)
        let data = try JSONEncoder.iso.encode(payload)

        try WiFiFileSystem.ensureDirectories()
        try data.write(to: localURL, options: .atomic)

        if allowICloudStorage, let iCloudDir = WiFiFileSystem.iCloudExportDir {
            let icURL = iCloudDir.appendingPathComponent(fileName)
            try data.write(to: icURL, options: .atomic)
        }
        return localURL
    }

    // MARK: - Import (.json / .js / .txt) with security-scoped URL + merge by BSSID

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
            if let b = it.bssid?.lowercased(), !b.isEmpty {
                indexByBSSID[b] = i
            }
        }

        for var nw in incoming {
            guard let bss = nw.bssid?.lowercased(), !bss.isEmpty else { continue }
            if let idx = indexByBSSID[bss] {
                // Ghi đè: giữ id cũ
                nw.id = items[idx].id
                items[idx] = nw
            } else {
                items.append(nw)
            }
        }
        persistToDisk()
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
