import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

enum CurrentWiFi {
    static func currentSSID() async -> String? {
        // CNCopy... có thể trả nil trên iOS mới; dùng best-effort
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for ifname in interfaces {
            if let dict = CNCopyCurrentNetworkInfo(ifname as CFString) as? [String: Any],
               let ssid = dict[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        return nil
    }

    static func connectIfSaved(store: WiFiStore, ssid: String?) async {
        guard let ssid, let net = store.networks.first(where: { $0.ssid == ssid }) else { return }
        await connect(net)
    }

    static func connect(_ net: WiFiNetwork) async {
        let conf: NEHotspotConfiguration
        if net.security == .none {
            conf = NEHotspotConfiguration(ssid: net.ssid)
        } else {
            conf = NEHotspotConfiguration(ssid: net.ssid, passphrase: net.password, isWEP: net.security == .wep)
        }
        conf.joinOnce = false
        try? await NEHotspotConfigurationManager.shared.apply(conf)
    }
}
