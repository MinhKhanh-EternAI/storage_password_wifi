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
            sources: ["Sources/**"],
            resources: [],              // để trống nhằm tránh lỗi AppIcon khi chưa có PNG
            entitlements: .file(path: "WiFiOffline.entitlements"),
            dependencies: [],
            settings: .settings()
        )
    ]
)
