import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    targets: [
        .target(
            name: "WiFiOffline",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.example.wifioffline",
            deploymentTargets: .iOS("14.0"),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: []
        )
    ]
)
