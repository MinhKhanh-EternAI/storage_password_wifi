import ProjectDescription

let project = Project(
    name: "WiFiOffline",
    packages: [
        .remote(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            requirement: .upToNextMajor(from: "12.0.0")
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
                "Assets.xcassets",
                "GoogleService-Info.plist"
            ],
            entitlements: .file(path: "WiFiOffline.entitlements"),
            dependencies: [
                // Firebase dependencies
                .package(product: "FirebaseCore"),
                .package(product: "FirebaseFirestore"),
                .package(product: "FirebaseAuth"),
            ],
            settings: .settings(base: [
                "SWIFT_VERSION": "5.0",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "INFOPLIST_FILE": "Info.plist",

                // Nếu build unsigned IPA để CI/CD thì giữ NO
                // Nếu muốn chạy trên thiết bị thật thì bỏ dòng này
                "CODE_SIGNING_ALLOWED": "NO"
            ])
        )
    ]
)
