import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    options: .options(
        automaticSchemesOptions: .disabled
    ),
    settings: .settings(),
    targets: [
        Target(
            name: "WiFiOffline",
            destinations: .iOS,                 // iPhone/iPad nếu muốn: [.iPhone, .iPad]
            product: .app,
            bundleId: "com.example.wifioffline",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: [
                "Assets.xcassets/**",
                "README.md"
            ],
            entitlements: .file(path: "WiFiOffline.entitlements"),
            settings: .settings(base: [
                "SWIFT_VERSION": "5.0",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "INFOPLIST_FILE": "Info.plist",
                "CODE_SIGNING_ALLOWED": "NO"
            ])
        )
    ],
    schemes: [
        Scheme(
            name: "WiFiOffline",
            buildAction: .buildAction(targets: ["WiFiOffline"]),
            runAction: .runAction(configuration: .release)
        )
    ]
)
