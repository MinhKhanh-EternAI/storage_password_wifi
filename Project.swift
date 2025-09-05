import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    organizationName: "MinhKhanh",
    packages: [],
    targets: [
        Target(
            name: "WiFiOffline",
            destinations: .iOS, // chỉ iPhone, nếu muốn universal thì .iOS([.iPhone, .iPad])
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
            buildAction: .buildAction(targets: ["WiFiOffline"]),
            runAction: .runAction(configuration: .release)
        )
    ]
)
