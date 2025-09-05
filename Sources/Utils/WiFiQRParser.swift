import Foundation

enum WiFiQRParser {
    static func parse(_ text: String) -> WiFiNetwork? {
        guard text.hasPrefix("WIFI:") else { return nil }
        let body = text.dropFirst(5)

        var dict: [String:String] = [:]
        var key = ""; var value = ""
        var readingKey = true; var escaping = false

        func flush() {
            if !key.isEmpty { dict[key] = value }
            key = ""; value = ""
        }

        for ch in body {
            if escaping {
                if readingKey { key.append(ch) } else { value.append(ch) }
                escaping = false; continue
            }
            switch ch {
            case "\\": escaping = true
            case ":" where readingKey: readingKey = false
            case ";" where !readingKey: flush(); readingKey = true
            default:
                if readingKey { key.append(ch) } else { value.append(ch) }
            }
        }
        flush()

        var wifi = WiFiNetwork()
        wifi.ssid = dict["S"] ?? ""
        wifi.password = dict["P"] ?? ""
        if let t = dict["T"]?.uppercased() {
            switch t {
            case "WEP": wifi.security = .wep
            case "WPA": wifi.security = .wpa2Wpa3
            case "NOPASS": wifi.security = .none
            default: break
            }
        }
        return wifi.ssid.isEmpty ? nil : wifi
    }
}
