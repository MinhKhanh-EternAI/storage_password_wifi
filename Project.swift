// Project.swift — Tuist 4
import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    targets: [
        .target(
            name: "WiFiOffline",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.example.wifioffline",     // đổi nếu muốn
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Info.plist"),

            // ⚠️ Thứ tự đúng: sources → resources → (headers) → entitlements
            sources: ["Sources/**"],
            resources: [],

            // (headers: nil,)  // không cần thì bỏ
            entitlements: .file(path: "WiFiOffline.entitlements"),

            dependencies: [],
            settings: .settings()
        )
    ]
)
