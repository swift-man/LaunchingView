# ``LaunchingView``

This is a SwiftUI view based on [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

## Overview

Use LaunchingView to show launch content while the app checks update, notice, and startup state.

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

### Custom Your Keys
```swift
import Dependencies
import LaunchingService

extension RemoteConfigRegisterdKeys: DependencyKey {
  public static var liveValue = RemoteConfigRegisterdKeys(#...#)
}
```

### Custom Your Alert Default Text

```swift
import Dependencies
import LaunchingView

extension LaunchingAlertDefaultText: DependencyKey {
  public static var liveValue = LaunchingAlertDefaultText(#...#)
}

```
