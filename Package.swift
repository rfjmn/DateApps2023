// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AccountCore",
    platforms: [.macOS(.v12)],
    targets: [
        .target(name: "AccountCore", path: "DateApps2023", exclude: [
            "AppDelegate.swift", "SceneDelegate.swift", "ViewController.swift", "Home", "Login", "Signup",
            "Info.plist", "GoogleService-Info.plist", "Assets.xcassets", "Base.lproj", "Model", "Data",
            "Presentation/AuthenticationModule.swift",
        ], sources: ["Domain", "Presentation/AuthenticationViewModel.swift"]),
        .testTarget(name: "AccountCoreTests", dependencies: ["AccountCore"]),
    ]
)
