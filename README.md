# 📶 WiFi Database (Vibe Code)



Ứng dụng iOS (SwiftUI) cho phép **lưu trữ và quản lý mật khẩu Wi-Fi ngoại tuyến** - dự án phục vụ mục đích cá nhân.

## 🎨 Giao diện

### Màn hình chính
| Chế độ sáng | Chế độ tối |
|-------------|------------|
| ![Homepage Light](demo/homepage-light.jpg) | ![Homepage Dark](demo/homepage-dark.jpg) |

### Thêm WiFi mới
| Chế độ sáng | Chế độ tối |
|-------------|------------|
| ![Add WiFi Light](demo/add-wifi-light.jpg) | ![Add WiFi Dark](demo/add-wifi-dark.jpg) |

### Chi tiết WiFi
| Chế độ sáng | Chế độ tối |
|-------------|------------|
| ![WiFi Info Light](demo/wifi-info-light.jpg) | ![WiFi Info Dark](demo/wifi-info-dark.jpg) |

## ✨ Tính năng

### 🔥 Core Features
- **Hiển thị mạng Wi-Fi hiện tại**
- **Thêm Wi-Fi thủ công**
- **Danh sách Wi-Fi thông minh**
- **Tìm kiếm nhanh**
- **Xuất/Nhập JSON**

### 🎯 Chi tiết WiFi
- **Hiện mật khẩu**
- **QR code chia sẻ**
- **Chỉnh sửa bảo mật**
- **Xoá có xác nhận**

### 🎨 UX/UI
- **Swipe to delete**
- **Dark/Light mode**
- **Smooth animations**
## 🛠 Tech Stack

```swift
// Vì sao chọn SwiftUI?
// - Declarative UI (ít code hơn, bug ít hơn)
// - Native performance
// - Tương lai của iOS development
```

### Requirements
- **iOS 16.0+** - Vì iOS cũ quá thì... cũ
- **Swift 5.9+** - Syntax mới, performance tốt
- **Xcode 15+** - Tool mới nhất cho dev mới nhất

### Permissions
```xml
<!-- Vì Apple yêu cầu -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>App cần quyền vị trí để lấy thông tin WiFi hiện tại</string>

<!-- Entitlement cho WiFi info -->
<key>com.apple.developer.networking.wifi-info</key>
<true/>
```

## 🚀 Cài đặt & Chạy

```bash
# Clone repo (nếu thích thì fork luôn)
git clone https://github.com/MinhKhanh-EternAI/storage_password_wifi
cd storage_password_wifi

# Generate project với Tuist
tuist generate

# Mở Xcode và code thôi!
open WiFiOffline.xcworkspace
```

## 🎯 Roadmap (nếu có thời gian)

- [ ] **iCloud Sync** - Sync giữa các device
- [ ] **Widget** - Hiển thị WiFi hiện tại trên home screen
- [ ] **Shortcuts** - Tích hợp với Siri Shortcuts
- [ ] **Export PDF** - In danh sách WiFi ra giấy (old school)
- [ ] **Biometric Lock** - Bảo mật bằng Face ID/Touch ID

## 🤝 Contributing

Đây là dự án cá nhân, nhưng nếu bạn có ý tưởng hay hoặc tìm thấy bug, cứ tạo issue hoặc PR nhé! 

*"Code is poetry, bugs are features"* 🐛✨

## 📝 License

MIT License - Dùng thoải mái, nhưng nhớ credit tác giả nhé! 

---

*Made with ❤️ and ☕ by [MinhKhanh-EternAI](https://github.com/MinhKhanh-EternAI)*
