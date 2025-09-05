import Foundation

struct ParsedWiFiQR {
    let ssid: String
    let password: String
    let type: String // "WPA", "WEP", "nopass", ...
}

enum WiFiQRParser {
    static func parse(_ raw: String) -> ParsedWiFiQR? {
        // Hỗ trợ dạng WIFI:T:WPA;S:MySSID;P:mypass;;
        guard raw.uppercased().hasPrefix("WIFI:") else { return nil }
        let body = String(raw.dropFirst(5))

        var t = ""
        var s = ""
        var p = ""

        func unescape(_ s: String) -> String {
            var out = ""
            var escape = false
            for ch in s {
                if escape {
                    out.append(ch)
                    escape = false
                } else if ch == "\\" {
                    escape = true
                } else {
                    out.append(ch)
                }
            }
            return out
        }

        // tách theo ; nhưng giữ escape
        var key = ""
        var value = ""
        var readingKey = true

        func flushPair() {
            if key.isEmpty { return }
            let K = key.uppercased()
            if K == "T" { t = value }
            else if K == "S" { s = value }
            else if K == "P" { p = value }
        }

        for ch in body {
            if readingKey && ch == ":" {
                readingKey = false
            } else if ch == ";" {
                flushPair()
                key = ""
                value = ""
                readingKey = true
            } else {
                if readingKey { key.append(ch) } else { value.append(ch) }
            }
        }
        flushPair()

        return ParsedWiFiQR(ssid: unescape(s),
                            password: unescape(p),
                            type: unescape(t))
    }
}
