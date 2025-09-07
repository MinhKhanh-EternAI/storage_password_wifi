# 📶 WiFiOffline

> *"Vì đôi khi bạn cần lưu mật khẩu WiFi của hàng xóm... một cách lịch sự"* 😏

Ứng dụng iOS (SwiftUI) cho phép **lưu trữ và quản lý mật khẩu Wi-Fi ngoại tuyến** - dự án cá nhân được code với đam mê và một chút tinh nghịch.

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
- **Hiển thị mạng Wi-Fi hiện tại** - Vì đôi khi bạn quên mình đang kết nối mạng gì
- **Thêm Wi-Fi thủ công** - Hoặc "mượn" từ mạng hiện tại (shh... 🤫)
- **Danh sách Wi-Fi thông minh** - Tự động sắp xếp theo tên, vì ai cũng thích thứ tự
- **Tìm kiếm nhanh** - Tìm WiFi trong tích tắc
- **Xuất/Nhập JSON** - Backup dữ liệu như một pro

### 🎯 Chi tiết WiFi
- **Hiện mật khẩu** - Copy nhanh, paste nhanh, kết nối nhanh
- **QR code chia sẻ** - Chia sẻ WiFi một cách cool ngầu
- **Chỉnh sửa bảo mật** - Tùy chỉnh theo ý muốn
- **Xoá có xác nhận** - Tránh xoá nhầm (đã từng xoá nhầm rồi... 😅)

### 🎨 UX/UI
- **Swipe to delete** - Xoá nhanh từ màn hình chính
- **Dark/Light mode** - Icon tự đổi ☀️🌙 theo tâm trạng
- **Smooth animations** - Mượt mà như bơ

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

## 💡 Tại sao tạo app này?

1. **Thực tế**: Đi cafe, nhà bạn, khách sạn... WiFi password dài quá, ghi note thì mất
2. **Học hỏi**: SwiftUI, Core Data, Network framework
3. **Tiện ích**: App cá nhân, không cần App Store, không cần review
4. **Fun**: Code cho vui, thử nghiệm UI/UX mới

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
