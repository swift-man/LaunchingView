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
@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct LaunchingView<Content: View, LaunchScreen: View>: View {
  @StateObject
  private var viewStore: ViewStore<Launching.State, Launching.Action>
  
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
    self._viewStore = StateObject(
      wrappedValue: ViewStore(
        Store(initialState: Launching.State()) {
          Launching()
        },
        observe: { $0 }
      )
    )
  }
  
  public var body: some View {
    launchContent(viewStore: viewStore)
      .onChange(of: scenePhase, perform: handleScenePhaseChange)
      .alert(optionalUpdateAlertBinding, action: handleAlertAction)
      .alert(appUpdateFetchErrorAlertBinding, action: handleAlertAction)
      .alert(noticeAlertBinding, action: handleAlertAction)
  }

  private var optionalUpdateAlertBinding: Binding<AlertState<Launching.Action>?> {
    viewStore.binding(
      get: { $0.optionalUpdateAlert },
      send: .optionalUpdateAlertDismissed
    )
  }

  private var appUpdateFetchErrorAlertBinding: Binding<AlertState<Launching.Action>?> {
    viewStore.binding(
      get: { $0.appUpdateFetchErrorAlert },
      send: .appUpdateFetchErrorAlertDismissed
    )
  }

  private var noticeAlertBinding: Binding<AlertState<Launching.Action>?> {
    viewStore.binding(
      get: { $0.noticeAlert },
      send: .noticeAlertDismissed
    )
  }

  @ViewBuilder
  private func launchContent(viewStore: ViewStore<Launching.State, Launching.Action>) -> some View {
    if let blockingAlert = viewStore.blockingAlert {
      blockingLaunchView(blockingAlert, viewStore: viewStore)
    } else if viewStore.displayContentView && isUserCustomFlagFinished {
      contentView()
    } else {
      launchScreen()
        .onAppear {
          viewStore.send(.fetchAppUpdateStatus)
        }
    }
  }

  private func blockingLaunchView(
    _ blockingAlert: Launching.State.BlockingAlert,
    viewStore: ViewStore<Launching.State, Launching.Action>
  ) -> BlockingLaunchView {
    BlockingLaunchView(
      title: blockingAlert.title,
      message: blockingAlert.message,
      buttonTitle: blockingAlert.buttonTitle,
      linkURL: blockingAlert.linkURL,
      onButtonTapped: { linkURL in
        viewStore.send(.blockingAlertButtonTapped(linkURL: linkURL))
      }
    )
  }

  private func handleScenePhaseChange(_ scenePhase: ScenePhase) {
    guard scenePhase == .active else { return }
    viewStore.send(.fetchAppUpdateStatus)
  }

  private func handleAlertAction(_ action: Launching.Action?) {
    guard let action else { return }
    viewStore.send(action)
  }
}
