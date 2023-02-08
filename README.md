# LaunchingView

This is a SwiftUI view based on The [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

![Badge](https://img.shields.io/badge/swift-white.svg?style=flat-square&logo=Swift)
![Badge](https://img.shields.io/badge/SwiftUI-001b87.svg?style=flat-square&logo=Swift&logoColor=black)
![Badge - Version](https://img.shields.io/badge/Version-0.6.0-1177AA?style=flat-square)
![Badge - Swift Package Manager](https://img.shields.io/badge/SPM-compatible-orange?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/platform-mac_12|ios_15-yellow?style=flat-square)
![Badge - License](https://img.shields.io/badge/license-MIT-black?style=flat-square)  

---

## Setup View
```swift
import LaunchingView

@main
struct YourApp: App {
  @Dependency(\.launchingService) var launchingService
  
  var body: some Scene {
    WindowGroup {
      LaunchingView<ContentView, LaunchScreenView>(
        store: Store(
          initialState: Launching.State(),
          reducer: Launching(launchingInteractor: launchingService)
        ),
        contentView: {
          ContentView()
        },
        launchScreen: {
          LaunchScreenView()
        })
    }
  }
}
```

## Dependency 
[AppVersionService](https://github.com/swift-man/LaunchingService) calls api using [FirebaseRemoteConfig](https://github.com/firebase/firebase-ios-sdk).

```swift
import Dependencies
import LaunchingService

extension LaunchingService: DependencyKey, LaunchingInteractable {
  public static var liveValue = LaunchingService(keyStore: LaunchingServiceKeyStore())
}

extension DependencyValues {
  var launchingService: LaunchingService {
    get { self[LaunchingService.self] }
    set { self[LaunchingService.self] = newValue }
  }
}
```

## Installation
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/swift-man/LaunchingView.git", .from: "0.5.1")
]
```
