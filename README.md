# 📶 WiFiOffline

Ứng dụng iOS (SwiftUI) cho phép **lưu trữ và quản lý mật khẩu Wi-Fi ngoại tuyến**.

## ✨ Tính năng
- Hiển thị mạng Wi-Fi hiện tại (yêu cầu cấp quyền vị trí + entitlements).
- Thêm Wi-Fi thủ công hoặc từ mạng hiện tại.
- Danh sách Wi-Fi đã lưu, tự động sắp xếp theo tên.
- Tìm kiếm Wi-Fi.
- Xuất/Nhập danh sách Wi-Fi (JSON).
- Xem chi tiết Wi-Fi đã lưu:
  - Hiện mật khẩu (copy nhanh).
  - QR code chia sẻ.
  - Chỉnh sửa bảo mật & chính sách MAC.
  - Xoá (có xác nhận).
- Xoá nhanh từ màn hình chính bằng swipe.
- Chế độ giao diện: **Hệ thống / Sáng / Tối** (icon góc trái tự đổi ☀️🌙).

## 🛠 Cấu hình
- iOS 16.0+
- Swift 5.9+
- Xcode 15+
- Quyền:
  - `NSLocationWhenInUseUsageDescription`
  - Entitlement `com.apple.developer.networking.wifi-info`

## 🚀 Cài đặt
```bash
git clone https://github.com/MinhKhanh-EternAI/storage_password_wifi
cd storage_password_wifi
tuist generate
open WiFiOffline.xcworkspace
