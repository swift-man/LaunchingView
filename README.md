# LaunchingView

`LaunchingView`는 앱 시작 시점에 서버에서 내려주는 실행 정책을 확인하고, 그 결과에 따라 본 화면, 런치 화면, 업데이트 안내, 공지, 차단 화면을 보여주는 SwiftUI 패키지입니다. 내부 상태 관리는 [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)를 기반으로 합니다.

앱을 배포한 뒤에도 사용자의 진입 흐름을 원격으로 제어해야 하는 상황을 다룹니다. 예를 들어 필수 업데이트가 필요한 버전은 업데이트 화면에 머물게 하고, 선택 업데이트나 공지는 alert로 안내하며, 점검이나 서비스 중단 공지는 앱을 강제 종료하지 않고 차단 화면으로 유지합니다.

![Badge](https://img.shields.io/badge/swift-white.svg?style=flat-square&logo=Swift)
![Badge](https://img.shields.io/badge/SwiftUI-001b87.svg?style=flat-square&logo=Swift&logoColor=black)
![Badge - Version](https://img.shields.io/badge/Version-0.9.1-1177AA?style=flat-square)
![Badge - Swift Package Manager](https://img.shields.io/badge/SPM-compatible-orange?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/macOS-v13.0-yellow?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/iOS-v16.0-yellow?style=flat-square)
![Badge - License](https://img.shields.io/badge/license-MIT-black?style=flat-square)

---
## 문서

[LaunchingView](https://docs.gorani.me/LaunchingView/documentation/launchingview/)

## 이 저장소가 하는 일

`LaunchingView`는 앱의 첫 화면 앞단에서 다음 흐름을 처리합니다.

- 앱 실행 또는 foreground 복귀 시 원격 설정을 다시 조회합니다.
- 정상 상태이면 앱의 실제 `ContentView`를 보여줍니다.
- 사용자가 기다려야 하는 초기 작업이 있으면 커스텀 launch screen을 유지합니다.
- 선택 업데이트가 필요하면 사용자는 나중에 진행하거나 App Store URL을 열 수 있습니다.
- 강제 업데이트나 종료형 공지가 필요하면 앱을 종료하지 않고 차단 화면을 보여줍니다.
- 원격 설정 조회가 실패하면 에러 alert를 보여주고 dismiss 후 다시 조회합니다.

원격 설정 조회 자체는 [LaunchingService](https://github.com/swift-man/LaunchingService)가 담당합니다. 이 저장소는 그 결과를 SwiftUI 화면과 TCA reducer 상태 전이로 연결하는 presentation layer 역할을 합니다.

## 주요 컴포넌트

- `LaunchingView`: 동기/사용자 정의 launch screen 흐름에 사용합니다. `isFinished` binding으로 앱 자체 초기화 작업이 끝날 때까지 본 화면 노출을 지연할 수 있습니다.
- `AsyncLaunchingView`: 별도의 launch screen 없이 원격 실행 정책만 확인한 뒤 content를 보여주는 간단한 흐름에 사용합니다.
- `BlockingLaunchView`: 강제 업데이트나 종료형 공지처럼 사용자가 본 화면으로 진행하면 안 되는 상태를 표시합니다.
- `LaunchingAlertDefaultText`: 원격 설정에 문구가 비어 있을 때 사용할 기본 alert 문구를 주입합니다.
- `RemoteConfigRegisterdKeys`: `LaunchingService`가 읽을 Firebase Remote Config key를 앱에서 교체할 수 있게 합니다.

## 요구 사항

- Swift 6.1 이상
- iOS 16.0 이상
- macOS 13.0 이상
- Swift Package Manager

## 동작 방식

1. `LaunchingView` 또는 `AsyncLaunchingView`가 나타나면 `LaunchingService`를 통해 앱 업데이트 상태를 가져옵니다.
2. 상태가 `.valid`이면 content view를 노출합니다.
3. 상태가 `.optionalUpdateRequired`이면 선택 업데이트 alert를 표시합니다.
4. 상태가 `.forcedUpdateRequired`이면 업데이트 URL을 열 수 있는 차단 화면을 표시합니다.
5. 상태가 `.notice`이면 공지 alert 또는 차단 화면을 표시합니다.
6. 앱이 다시 active 상태가 되면 최신 정책을 다시 확인합니다.

## 화면 설정

### 기본 LaunchingView

커스텀 launch screen을 보여주다가 원격 상태 확인이 끝나면 본 화면으로 전환합니다.

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

### 앱 초기화 작업과 함께 사용

앱 내부 초기화, 애니메이션, 로그인 복원 같은 별도 작업이 끝날 때까지 본 화면 표시를 미룰 수 있습니다.

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

### 간단한 비동기 진입

별도의 launch screen이 필요 없고 content를 바로 감싸고 싶을 때 사용합니다.

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

## 의존성 및 설정

[LaunchingService](https://github.com/swift-man/LaunchingService)는 [FirebaseRemoteConfig](https://github.com/firebase/firebase-ios-sdk)를 통해 실행 정책을 조회합니다. 앱에서는 Firebase 초기화와 Remote Config key 설정을 준비해야 합니다.

### Remote Config key 교체

앱에서 사용하는 Remote Config key가 기본값과 다르면 `RemoteConfigRegisterdKeys`를 dependency로 교체합니다.

```swift
import Dependencies
import LaunchingService

extension RemoteConfigRegisterdKeys: DependencyKey {
  public static var liveValue = RemoteConfigRegisterdKeys(#...#)
}
```

### 기본 alert 문구 교체

원격 설정에서 title/message가 비어 있을 때 사용할 기본 문구를 앱 정책에 맞게 바꿀 수 있습니다.

```swift
import Dependencies
import LaunchingView

extension LaunchingAlertDefaultText: DependencyKey {
  public static var liveValue = LaunchingAlertDefaultText(#...#)
}

```

## 설치

### Swift Package Manager

`Package.swift`의 `dependencies`에 다음 항목을 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/swift-man/LaunchingView.git", from: "0.9.1")
]
```
