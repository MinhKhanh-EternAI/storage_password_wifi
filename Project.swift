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
      // Tuist 4.x: dùng 'destinations' thay cho platform/devices
      name: "WiFiOffline",
      destinations: .iOS,                 // [.iPhone, .iPad] nếu muốn universal
      product: .app,
      bundleId: "com.example.wifioffline",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .file(path: "Info.plist"),

      // Thứ tự đúng: sources trước entitlements
      sources: ["Sources/**"],
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
