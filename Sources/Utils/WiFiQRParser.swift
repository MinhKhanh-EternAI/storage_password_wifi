import Foundation

/// Parse QR theo chuẩn: WIFI:T:WPA;S:ssid;P:pass;;
enum WiFiQRParser {
    static func parse(_ text: String) -> WiFiNetwork? {
        guard text.uppercased().hasPrefix("WIFI:") else { return nil }
        let body = String(text.dropFirst("WIFI:".count))

        var fields: [String: String] = [:]
        var key = ""
        var value = ""
        var readingKey = true
        var esc = false

        func putKV() {
            if !key.isEmpty {
                fields[key] = value
            }
            key = ""; value = ""; readingKey = true
        }

        for ch in body {
            if esc {
                if readingKey { key.append(ch) } else { value.append(ch) }
                esc = false
            } else if ch == "\\" {
                esc = true
            } else if ch == ":" && readingKey {
                readingKey = false
            } else if ch == ";" {
                putKV()
            } else {
                if readingKey { key.append(ch) } else { value.append(ch) }
            }
        }

        let t = fields["T"]?.uppercased() ?? fields["t"]?.uppercased()
        let s = fields["S"] ?? fields["s"]
        let p = fields["P"] ?? fields["p"]

        guard let ssid = s, !ssid.isEmpty else { return nil }
        let sec: WiFiNetwork.Security
        switch t {
        case nil, .some(""), .some("NOPASS"): sec = .open
        case .some("WEP"): sec = .wep
        case .some("WPA"), .some("WPA2"): sec = .wpa2
        case .some("WPA3"): sec = .wpa3
        default: sec = .wpa2
        }
        return WiFiNetwork(ssid: ssid, password: p ?? "", security: sec)
    }
}
