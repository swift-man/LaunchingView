//
//  AsyncLaunchingView.swift
//  
//
//  Created by SwiftMan on 2023/02/11.
//

import ComposableArchitecture
import SwiftUI

@available(iOS 16.0, macOS 13, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct AsyncLaunchingView<Content: View>: View {
  @State
  private var store: StoreOf<Launching>
  
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
    } else {
      contentView()
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
