import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    packages: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.2.0")
    ],
    targets: [
        .target(
            name: "WiFiOffline",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.wifioffline",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: ["Assets.xcassets/**", "README.md"],
            entitlements: .file(path: "WiFiOffline.entitlements"),
            dependencies: [
                .package(product: "FirebaseCore", package: "firebase-ios-sdk"),
                .package(product: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            settings: .settings(base: [
                "SWIFT_VERSION": "5.0",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "INFOPLIST_FILE": "Info.plist",
                "CODE_SIGNING_ALLOWED": "NO"
            ])
        )
    ]
)
