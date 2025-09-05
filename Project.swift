import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    organizationName: "MinhKhanh",
    packages: [],
    settings: .settings(),
    targets: [
        Target(
            name: "WiFiOffline",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.example.wifioffline",
            deploymentTargets: .iOS("16.0"),
            infoPlist: "Info.plist",
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
            buildAction: BuildAction(targets: ["WiFiOffline"]),
            runAction: RunAction(configuration: .release)
        )
    ]
)
