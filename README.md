# Wi-fi (WiFi Offline)

App SwiftUI iOS 16+ để lưu/hiển thị/quét và chia sẻ thông tin Wi-Fi (offline).  
- Lưu tại `Documents/wifi.json` (không yêu cầu đăng nhập).  
- Quét/hiển thị QR theo chuẩn `WIFI:T:...;S:...;P:...;;`.  
- Hỗ trợ HotspotConfiguration (cần ký app với entitlement để kết nối tự động).

## Build bằng Tuist + CI
- File `Project.swift` dùng Tuist 4.
- Workflow: `.github/workflows/build-unsigned-ipa-tuist.yml` (upload artifact với v4).
