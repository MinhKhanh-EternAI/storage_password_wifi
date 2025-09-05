// Project.swift — Tuist 4
import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    targets: [
        .target(
            name: "WiFiOffline",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.example.wifioffline",   // đổi nếu muốn
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Info.plist"),
            entitlements: .file(path: "WiFiOffline.entitlements"), // 👈 thêm dòng này
            sources: ["Sources/**"],
            resources: []
        )
    ]
)
