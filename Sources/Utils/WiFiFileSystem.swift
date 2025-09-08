import Foundation

/// Quản lý cây thư mục của app trong Files (Documents) và iCloud Drive.
/// Đảm bảo không lặp "Wi-Fi/Wi-Fi".
enum WiFiFileSystem {
    // MARK: - App Documents
    static var appDocuments: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Thư mục chuẩn dưới appDocuments
    static var localExportDir: URL   { appDocuments.appendingPathComponent("Export",   isDirectory: true) }
    static var localDatabaseDir: URL { appDocuments.appendingPathComponent("Database", isDirectory: true) }
    static var localDatabaseFile: URL { localDatabaseDir.appendingPathComponent("wifi-database.json") }

    // MARK: - Tương thích code 2 (~/Documents/Wi-Fi)
    static var legacyLocalDir: URL {
        appDocuments.appendingPathComponent("Wi-Fi", isDirectory: true)
    }

    static var legacyLocalDatabaseFile: URL {
        legacyLocalDir.appendingPathComponent("wifi-database.js", conformingTo: .data)
    }

    // MARK: - iCloud (nếu bật iCloud Documents)
    static var iCloudAppRoot: URL? {
        guard let c = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        return c.appendingPathComponent("Documents", isDirectory: true)
    }
    static var iCloudExportDir: URL?   { iCloudAppRoot?.appendingPathComponent("Export",   isDirectory: true) }
    static var iCloudDatabaseDir: URL? { iCloudAppRoot?.appendingPathComponent("Database", isDirectory: true) }
    static var iCloudDatabaseFile: URL? { iCloudDatabaseDir?.appendingPathComponent("wifi-database.json") }

    // MARK: - Ensure Directories
    /// Tạo thư mục cần thiết (local + iCloud) và migrate khỏi thư mục lót cũ nếu có.
    static func ensureDirectories() {
        createDir(localExportDir)
        createDir(localDatabaseDir)

        // iCloud
        if let ic = iCloudAppRoot {
            createDir(ic)
            if let d = iCloudDatabaseDir { createDir(d) }
            if let e = iCloudExportDir   { createDir(e) }
        }

        // Thư mục legacy (~/Documents/Wi-Fi) từ code 2
        let fm = FileManager.default
        if !fm.fileExists(atPath: legacyLocalDir.path) {
            try? fm.createDirectory(at: legacyLocalDir, withIntermediateDirectories: true)
        }

        migrateFromNestedIfNeeded()
    }

    private static func createDir(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    // MARK: - Migration
    /// Di chuyển nội dung từ Documents/"Wi-Fi" cũ ra thẳng Documents (fix lặp Wi-Fi/Wi-Fi)
    private static func migrateFromNestedIfNeeded() {
        let nested = appDocuments.appendingPathComponent("Wi-Fi", isDirectory: true)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: nested.path, isDirectory: &isDir), isDir.boolValue else { return }

        moveContents(of: nested.appendingPathComponent("Export"),   to: localExportDir)
        moveContents(of: nested.appendingPathComponent("Database"), to: localDatabaseDir)
        try? FileManager.default.removeItem(at: nested)
    }

    private static func moveContents(of src: URL, to dst: URL) {
        createDir(dst)
        if let names = try? FileManager.default.contentsOfDirectory(atPath: src.path) {
            for name in names {
                let s = src.appendingPathComponent(name)
                let d = dst.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: d.path) { try? FileManager.default.removeItem(at: d) }
                try? FileManager.default.moveItem(at: s, to: d)
            }
        }
    }

    // MARK: - Export Filename
    /// Tên file export theo thời gian: wifi-YYYYMMDD-HHmmss.json
    static func makeTimestampedExportFileName(date: Date = .now) -> String {
        let f = DateFormatter()
        f.locale = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return "wifi-\(f.string(from: date)).json"
    }
}
