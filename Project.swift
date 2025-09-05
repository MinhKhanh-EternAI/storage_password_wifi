// Project.swift — Tuist 4
import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    targets: [
        .target(
            name: "WiFiOffline",
            destinations: [.iPhone],            // hoặc .iOS nếu hỗ trợ iPad
            product: .app,
            bundleId: "com.example.wifioffline", // ĐỔI cho khớp bundle của bạn
            deploymentTargets: .iOS("14.0"),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: []                        // thêm "Resources/**" nếu có tài nguyên
        )
    ]
)
