//
//  LaunchingView.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import ComposableArchitecture
import SwiftUI

/// LaunchingView는 App 구동전 스플레시 역할을 합니다.
///
/// 예측하지 못한 장애를 대응하거나,
/// 유저에게 빠른 배포를 위해 해당 기능이 필요할 수 있습니다.
///
/// TIP: 애플은 앱 구동이 늦어지는 것을 권장하지 않습니다.
///
/// Firebase.RemoteConfig 세팅이 필요합니다.
/// 자세한 내용은 Firebase ios SDK 를 참고해주세요.
///
///     import UIKit
///     import Firebase
///     import ComposableArchitecture
///     import LaunchingView
///     import Dependencies
///
///     class AppDelegate: NSObject, UIApplicationDelegate {
///       func application(_ application: UIApplication,
///                        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
///         FirebaseApp.configure()
///
///         return true
///       }
///     }
///
///     @main
///     struct YourApp: App {
///
///       // register app delegate for Firebase setup
///       @UIApplicationDelegateAdaptor(AppDelegate.self)
///       var delegate
///
///       var body: some Scene {
///         WindowGroup {
///           LaunchingView(
///             content: {
///               # RootView #
///             },
///             launchScreen: {
///               # LaunchScreenView #
///             }
///           )
///         }
///       }
///     }
@available(iOS 16.0, macOS 13, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct LaunchingView<Content: View, LaunchScreen: View>: View {
  @State
  private var store: StoreOf<Launching>
  
  private let contentView: () -> Content
  private let launchScreen: () -> LaunchScreen
  
  @Binding
  private var isUserCustomFlagFinished: Bool
  
  @Environment(\.scenePhase)
  private var scenePhase
  
  /// Creates a new LaunchingView
  ///
  /// This initializer always succeeds
  /// - Parameters:
  ///   - content: The callback that SwiftUI contentView
  ///   - launchScreen: The callback that SwiftUI launchScreen
  ///   - isFinished: Wait for your task to finish and show the content
  public init(
       @ViewBuilder content: @escaping () -> Content,
       @ViewBuilder launchScreen: @escaping () -> LaunchScreen,
       isFinished: Binding<Bool> = .constant(true)
  ) {
    self.contentView = content
    self.launchScreen = launchScreen
    self._isUserCustomFlagFinished = isFinished
    self._store = State(
      wrappedValue: Store(initialState: Launching.State()) {
        Launching()
      }
    )
  }
  
  public var body: some View {
    WithPerceptionTracking {
      @Perception.Bindable var store = store

      launchContent(store: store)
        .onChange(of: scenePhase, perform: handleScenePhaseChange)
        .alert($store.scope(state: \.optionalUpdateAlert, action: \.optionalUpdateAlert))
        .alert(
          $store.scope(
            state: \.appUpdateFetchErrorAlert,
            action: \.appUpdateFetchErrorAlert
          )
        )
        .alert($store.scope(state: \.noticeAlert, action: \.noticeAlert))
    }
  }

  @ViewBuilder
  private func launchContent(store: StoreOf<Launching>) -> some View {
    if let blockingAlert = store.blockingAlert {
      blockingLaunchView(blockingAlert, store: store)
    } else if store.displayContentView && isUserCustomFlagFinished {
      contentView()
    } else {
      launchScreen()
        .onAppear {
          store.send(.fetchAppUpdateStatus)
        }
    }
  }

  private func blockingLaunchView(
    _ blockingAlert: Launching.State.BlockingAlert,
    store: StoreOf<Launching>
  ) -> BlockingLaunchView {
    BlockingLaunchView(
      title: blockingAlert.title,
      message: blockingAlert.message,
      buttonTitle: blockingAlert.buttonTitle,
      linkURL: blockingAlert.linkURL,
      onButtonTapped: { linkURL in
        store.send(.blockingAlertButtonTapped(linkURL: linkURL))
      }
    )
  }

  private func handleScenePhaseChange(_ scenePhase: ScenePhase) {
    guard scenePhase == .active else { return }
    store.send(.fetchAppUpdateStatus)
  }
}
