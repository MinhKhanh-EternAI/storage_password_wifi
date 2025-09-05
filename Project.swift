// Project.swift — Tuist 4
import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    targets: [
        .target(
            name: "WiFiOffline",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.example.wifioffline",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Info.plist"),
            // 👇 thêm dòng này
            entitlements: .file(path: "WiFiOffline.entitlements"),
            sources: ["Sources/**"],
            resources: []
        )
    ]
)
