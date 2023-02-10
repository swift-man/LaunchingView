//
//  AsyncLaunchingView.swift
//  
//
//  Created by SwiftMan on 2023/02/11.
//

import ComposableArchitecture
import SwiftUI

public struct AsyncLaunchingView<Content: View>: View {
  private let store = Store(
    initialState: Launching.State(),
    reducer: Launching()
  )
  
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
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      contentView()
        .onAppear {
          viewStore.send(.fetchAppUpdateState)
        }
        .onChange(of: scenePhase) { newValue in
          if newValue == .active {
            viewStore.send(.fetchAppUpdateState)
          }
        }
    }
    .alert(
      self.store.scope(state: \.forceUpdateAlert),
      dismiss: .forceUpdateAlertDismissed
    )
    .confirmationDialog(
      self.store.scope(state: \.optionalUpdateConfirm),
      dismiss: .optionalUpdateConfirmDismissed
    )
    .alert(
      self.store.scope(state: \.appUpdateFetchErrorAlert),
      dismiss: .appUpdateFetchErrorAlertDismissed
    )
    .alert(
      self.store.scope(state: \.noticeAlert),
      dismiss: .noticeAlertDismissed
    )
  }
}
