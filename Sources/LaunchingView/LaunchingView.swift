//
//  LaunchingView.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import ComposableArchitecture
import SwiftUI

public struct LaunchingView<Content: View, LaunchScreen: View>: View {
  let store: StoreOf<Launching>
  
  @State
  var onLaunching = false
  
  let contentView: () -> Content
  let launchScreen: () -> LaunchScreen
  
  public init(store: StoreOf<Launching>,
       @ViewBuilder contentView: @escaping () -> Content,
       @ViewBuilder launchScreen: @escaping () -> LaunchScreen) {
    self.contentView = contentView
    self.launchScreen = launchScreen
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if onLaunching {
        contentView()
      } else {
        launchScreen()
          .onAppear {
            viewStore.send(.fetchAppUpdateState)
          }
          .onChange(of: viewStore.isValid) { newValue in
            onLaunching = newValue
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
  }
}
