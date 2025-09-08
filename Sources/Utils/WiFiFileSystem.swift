import Foundation

/// Quản lý cây thư mục:
///   Documents/Wi-Fi/{Database, Export}
/// và bản sao trên iCloud (nếu iCloud Drive khả dụng).
enum WiFiFileSystem {
    // Tên thư mục / file
    static let rootFolderName = "Wi-Fi"
    static let exportFolderName = "Export"
    static let databaseFolderName = "Database"
    static let databaseFileName = "wifi-database.json"

    // MARK: - Local (On My iPhone)

    static var localRoot: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(rootFolderName, isDirectory: true)
    }

    static var localExportDir: URL {
        localRoot.appendingPathComponent(exportFolderName, isDirectory: true)
    }

    static var localDatabaseDir: URL {
        localRoot.appendingPathComponent(databaseFolderName, isDirectory: true)
    }

    static var localDatabaseFile: URL {
        localDatabaseDir.appendingPathComponent(databaseFileName, isDirectory: false)
    }

    // MARK: - iCloud (Documents in iCloud Drive)

    /// Trả về thư mục gốc iCloud/Documents/Wi-Fi nếu iCloud khả dụng
    static var iCloudRoot: URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        return container.appendingPathComponent("Documents", isDirectory: true)
                        .appendingPathComponent(rootFolderName, isDirectory: true)
    }

    static var iCloudExportDir: URL? {
        iCloudRoot?.appendingPathComponent(exportFolderName, isDirectory: true)
    }

    static var iCloudDatabaseDir: URL? {
        iCloudRoot?.appendingPathComponent(databaseFolderName, isDirectory: true)
    }

    static var iCloudDatabaseFile: URL? {
        iCloudDatabaseDir?.appendingPathComponent(databaseFileName, isDirectory: false)
    }

    // MARK: - Ensure

    /// Tạo toàn bộ thư mục cần thiết (local + iCloud nếu có)
    static func ensureDirectories() {
        createDir(localRoot)
        createDir(localExportDir)
        createDir(localDatabaseDir)
        if let icRoot = iCloudRoot {
            createDir(icRoot)
            if let d = iCloudDatabaseDir { createDir(d) }
            if let e = iCloudExportDir { createDir(e) }
        }
    }

    private static func createDir(_ url: URL) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    // MARK: - Helpers

    /// Tên file export theo thời gian: wifi-YYYYMMDD-HHmmss.json
    static func makeTimestampedExportFileName(date: Date = .now) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyyMMdd-HHmmss"
        return "wifi-\(df.string(from: date)).json"
    }
}
