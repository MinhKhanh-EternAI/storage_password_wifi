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
      // Tuist 4.67.x: dùng deploymentTargets (không còn 'devices')
      deploymentTargets: .iOS("16.0"),
      infoPlist: .file(path: "Info.plist"),

      // Lưu ý: 'sources' phải đứng trước 'entitlements'
      sources: ["Sources/**"],
      resources: ["Assets/**"],

      entitlements: .file(path: "WiFiOffline.entitlements"),
      settings: .settings(base: [
        "SWIFT_VERSION": "5.0",
        "INFOPLIST_FILE": "Info.plist"
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
