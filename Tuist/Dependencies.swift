import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init([
        .remote(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            requirement: .upToNextMajor(from: "10.29.0")
        )
    ]),
    platforms: [.iOS]
)
