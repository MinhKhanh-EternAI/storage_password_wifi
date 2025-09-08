import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    packages: [
        .remote(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            requirement: .upToNextMajor(from: "10.29.0")
        )
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
            resources: [
                .glob(pattern: "Assets.xcassets/**"),
                .glob(pattern: "GoogleService-Info.plist"),
                .glob(pattern: "README.md")
            ],
            entitlements: .file(path: "WiFiOffline.entitlements"),
            dependencies: [
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseFirestore"),
                .external(name: "FirebaseAuth") // thêm nếu dùng
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
