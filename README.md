# LaunchingView

This is a SwiftUI view based on [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

![Badge](https://img.shields.io/badge/swift-white.svg?style=flat-square&logo=Swift)
![Badge](https://img.shields.io/badge/SwiftUI-001b87.svg?style=flat-square&logo=Swift&logoColor=black)
![Badge - Version](https://img.shields.io/badge/Version-0.9.1-1177AA?style=flat-square)
![Badge - Swift Package Manager](https://img.shields.io/badge/SPM-compatible-orange?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/macOS-v12.0-yellow?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/iOS-v15.0-yellow?style=flat-square)
![Badge - License](https://img.shields.io/badge/license-MIT-black?style=flat-square)

---
### Documentation Website
[LaunchingView](https://docs.gorani.me/LaunchingView/documentation/launchingview/)

## Feature
* [x] AsyncLaunchingView
* [x] AppLife Cycle - Become Active

## Setup View
### Sync Process
```swift
import LaunchingView

@main
struct YourApp: App {
  var body: some Scene {
    WindowGroup {
      LaunchingView(
        content: {
          ContentView()
        },
        launchScreen: {
          LaunchScreenView()
        }
      )
    }
  }
}
```

### Sync Process Animation or Task
```swift
import LaunchingView

@main
struct YourApp: App {
  @State
  var isFinished = false

  var body: some Scene {
    WindowGroup {
      LaunchingView(
        content: {
          ContentView()
        },
        launchScreen: {
          VStack {
            Image("ImageName")
            Button {
              isFinished = true
            } label: {
              Text("Task Finish!!").foregroundColor(Color.red)
            }
          }
        },
        isFinished: $isFinished
      )
    }
  }
}
```

### Async Process
```swift
import LaunchingView

@main
struct YourApp: App {
  var body: some Scene {
    WindowGroup {
      AsyncLaunchingView<ContentView> {
        ContentView()
      }
    }
  }
}
```

## Dependencies
[LaunchingService](https://github.com/swift-man/LaunchingService) calls api using [FirebaseRemoteConfig](https://github.com/firebase/firebase-ios-sdk).

### Customize Your Keys
```swift
import Dependencies
import LaunchingService

extension RemoteConfigRegisterdKeys: DependencyKey {
  public static var liveValue = RemoteConfigRegisterdKeys(#...#)
}
```

### Customize Your Alert Default Text

```swift
import Dependencies
import LaunchingView

extension LaunchingAlertDefaultText: DependencyKey {
  public static var liveValue = LaunchingAlertDefaultText(#...#)
}

```
## Installation
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding LaunchingView as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/swift-man/LaunchingView.git", from: "0.9.1")
]
```
