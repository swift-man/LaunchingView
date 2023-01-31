# LaunchingView

A description of this package.

## Setup View
```swift
import LaunchingView

@main
struct YourApp: App {
  @Dependency(\.appVersionService) var appVersionService
  
  var body: some Scene {
    WindowGroup {
      LaunchingView<ContentView, LaunchScreenView>(
        store: Store(
          initialState: Launching.State(),
          reducer: Launching(appVersionInteractor: appVersionService)
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

## Dependency AppVersionService

```swift
import Dependencies
import AppVersionService

extension AppVersionFetchService: DependencyKey, AppVersionInteractable {
  public static var liveValue = AppVersionFetchService(keyStore: AppVersionServiceKeyStore())
}

extension DependencyValues {
  var appVersionService: AppVersionFetchService {
    get { self[AppVersionFetchService.self] }
    set { self[AppVersionFetchService.self] = newValue }
  }
}
```
