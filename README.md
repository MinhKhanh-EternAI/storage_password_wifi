# WiFiOffline

Dự án iOS (SwiftUI) build bằng **Tuist 4** trên GitHub Actions, xuất **unsigned .ipa** hợp lệ (eSign/AltStore/Sideloadly có thể re-sign).

## Yêu cầu

- Tuist 4.x
- iOS Deployment Target: 14.0+

## Local

```bash
brew tap tuist/tuist
brew install --formula tuist
tuist generate