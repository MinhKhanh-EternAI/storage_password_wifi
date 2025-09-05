import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    organizationName: "MinhKhanh",
    packages: [],
    targets: [
        Target(
            name: "WiFiOffline",
            platform: .iOS,
            product: .app,
            bundleId: "com.example.wifioffline",
            deploymentTarget: .iOS(targetVersion: "16.0", devices: [.iphone]),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "WiFiOffline.entitlements",
            dependencies: []
        )
    ],
    schemes: [
        Scheme(
            name: "WiFiOffline",
            shared: true,
            buildAction: .buildAction(targets: ["WiFiOffline"]),
            runAction: .runAction(configuration: .release)
        )
    ]
)
