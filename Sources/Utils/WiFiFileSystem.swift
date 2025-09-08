import Foundation

/// Quản lý cây thư mục của app trong Files (Documents) và iCloud Drive.
/// KHÔNG lót thêm "Wi-Fi" lần nữa để tránh lặp.
enum WiFiFileSystem {
    // App Documents (Files hiển thị là tên app: "Wi-Fi")
    static var appDocuments: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Thư mục chuẩn cần có NGAY dưới thư mục app
    static var localExportDir: URL   { appDocuments.appendingPathComponent("Export",   isDirectory: true) }
    static var localDatabaseDir: URL { appDocuments.appendingPathComponent("Database", isDirectory: true) }
    static var localDatabaseFile: URL { localDatabaseDir.appendingPathComponent("wifi-database.json") }

    // iCloud (nếu bật iCloud Documents)
    static var iCloudAppRoot: URL? {
        guard let c = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        return c.appendingPathComponent("Documents", isDirectory: true)
    }
    static var iCloudExportDir: URL?   { iCloudAppRoot?.appendingPathComponent("Export",   isDirectory: true) }
    static var iCloudDatabaseDir: URL? { iCloudAppRoot?.appendingPathComponent("Database", isDirectory: true) }
    static var iCloudDatabaseFile: URL? { iCloudDatabaseDir?.appendingPathComponent("wifi-database.json") }

    /// Tạo thư mục cần thiết (local + iCloud) và migrate khỏi thư mục lót cũ nếu có.
    static func ensureDirectories() {
        createDir(localExportDir); createDir(localDatabaseDir)
        if let ic = iCloudAppRoot {
            createDir(ic)
            if let d = iCloudDatabaseDir { createDir(d) }
            if let e = iCloudExportDir   { createDir(e) }
        }
        migrateFromNestedIfNeeded()
    }

    private static func createDir(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

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

    /// Tên file export theo thời gian: wifi-YYYYMMDD-HHmmss.json
    static func makeTimestampedExportFileName(date: Date = .now) -> String {
        let f = DateFormatter(); f.locale = .init(identifier: "en_US_POSIX"); f.dateFormat = "yyyyMMdd-HHmmss"
        return "wifi-\(f.string(from: date)).json"
    }
}
