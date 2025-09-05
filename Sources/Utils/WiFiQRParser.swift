import Foundation

enum WiFiQRParser {
    struct Result { var ssid: String; var password: String; var type: String }

    static func parse(_ text: String) -> Result? {
        // Chuẩn: WIFI:T:WPA;S:SSID;P:password;;
        guard text.uppercased().hasPrefix("WIFI:") else { return nil }
        var ssid = "", pass = "", type = "WPA"

        let body = text.dropFirst(5) // after WIFI:
        for part in body.split(separator: ";") {
            let kv = part.split(separator: ":", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            switch kv[0].uppercased() {
            case "S": ssid = kv[1]
            case "P": pass = kv[1]
            case "T": type = kv[1]
            default: break
            }
        }
        guard !ssid.isEmpty else { return nil }
        return .init(ssid: ssid, password: pass, type: type)
    }
}
