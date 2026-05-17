//
//  AsyncLaunchingView.swift
//  
//
//  Created by SwiftMan on 2023/02/11.
//

import ComposableArchitecture
import SwiftUI

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct AsyncLaunchingView<Content: View>: View {
  @ObservedObject
  private var viewStore: ViewStore<Launching.State, Launching.Action>
  
  private let contentView: () -> Content
  
  @Environment(\.scenePhase)
  private var scenePhase
  
  /// Creates a new AsyncLaunchingView
  ///
  /// This initializer always succeeds
  /// - Parameters:
  ///   - content: The callback that SwiftUI contentView
  public init(@ViewBuilder content: @escaping () -> Content) {
    self.contentView = content
    let store = Store(
      initialState: Launching.State()
    ) {
      Launching()
    }
    self._viewStore = ObservedObject(wrappedValue: ViewStore(store, observe: { $0 }))
  }
  
  public var body: some View {
    let content = launchContent(viewStore: viewStore)
    let sceneContent = AnyView(
      content.onChange(of: scenePhase, perform: handleScenePhaseChange)
    )
    let optionalUpdateAlert = AnyView(sceneContent.alert(
      optionalUpdateAlertBinding,
      action: handleAlertAction
    ))
    let fetchErrorAlert = AnyView(optionalUpdateAlert.alert(
      appUpdateFetchErrorAlertBinding,
      action: handleAlertAction
    ))
    return AnyView(fetchErrorAlert.alert(
      noticeAlertBinding,
      action: handleAlertAction
    ))
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

  private func launchContent(viewStore: ViewStore<Launching.State, Launching.Action>) -> AnyView {
    if let blockingAlert = viewStore.blockingAlert {
      return AnyView(blockingLaunchView(blockingAlert, viewStore: viewStore))
    }

    return AnyView(
      contentView()
        .onAppear {
          viewStore.send(.fetchAppUpdateStatus)
        }
    )
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
