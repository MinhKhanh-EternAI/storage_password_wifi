import ProjectDescription

let project = Project(
  name: "WiFiOffline",
  organizationName: "example",
  options: .options(
    automaticSchemesOptions: .disabled,
    developmentRegion: "vi"
  ),
  targets: [
    Target(
      name: "WiFiOffline",
      platform: .iOS,
      product: .app,
      bundleId: "com.example.wifioffline",
      deploymentTarget: .iOS(targetVersion: "16.0", devices: [.iphone]),
      infoPlist: .file(path: "Info.plist"),
      sources: ["Sources/**"],           // (đặt trước entitlements để tránh lỗi tuist)
      resources: ["Assets/**"],
      entitlements: .file(path: "WiFiOffline.entitlements"),
      settings: .settings(base: [
        "SWIFT_VERSION": "5.0",
        "INFOPLIST_FILE": "Info.plist",
      ])
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
