//
//  LaunchingView.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import ComposableArchitecture
import SwiftUI

public struct LaunchingView<Content: View, LaungchScreen: View>: View {
  let store: StoreOf<Launching>
  
  @State
  var onLaunching: Bool = false
  
  let contentView: () -> Content
  let laungchScreen: () -> LaungchScreen
  
  public init(store: StoreOf<Launching>,
       @ViewBuilder contentView: @escaping () -> Content,
       @ViewBuilder laungchScreen: @escaping () -> LaungchScreen) {
    self.contentView = contentView
    self.laungchScreen = laungchScreen
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if onLaunching {
        contentView()
      } else {
        laungchScreen()
          .onAppear {
            viewStore.send(.fetchAppVersion)
          }
          .onChange(of: viewStore.isSuccess) { newValue in
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
      self.store.scope(state: \.fetchErrorAlert),
      dismiss: .fetchErrorAlertDismissed
    )
  }
}
