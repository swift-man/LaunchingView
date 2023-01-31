//
//  Launching.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import AppVersionService
import ComposableArchitecture
import SwiftUI

public struct Launching: ReducerProtocol {
  // MARK: - Enums
  public struct State: Equatable {
    var appVersionState: ResultAppVersion?
    var fetchErrorAlert: AlertState<Action>?
    var forceUpdateAlert: AlertState<Action>?
    var isSuccess: Bool = false
    var optionalUpdateConfirm: ConfirmationDialogState<Action>?
  }
  
  public enum Action: Equatable {
    case fetchAppVersion
    case fetchErrorAlertDismissed
    case fetchedAppVersionState(ResultAppVersion)
    case forceUpdateAlertDismissed
    case optionalUpdateConfirmDismissed
    case optionalUpdateConfirmTapped(appStoreURL: URL?)
    case showFetchErrorAlert(errorMessage: String)
  }
  
  let appVersionInteractor: AppVersionInteractable
  
  public init(appVersionInteractor: AppVersionInteractable) {
    self.appVersionInteractor = appVersionInteractor
  }
  
  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .fetchAppVersion:
      return .task {
        do {
          let state = try await appVersionInteractor.fetchAppVersion()
          return .fetchedAppVersionState(state)
        } catch {
          return .showFetchErrorAlert(errorMessage: error.localizedDescription)
        }
      }
    case .forceUpdateAlertDismissed:
      guard let appVersionState = state.appVersionState else { return .none }
      
      switch appVersionState {
      case .success:
        return .none
      case .forcedUpdateRequired(message: _, appstoreURL: let appstoreURL):
#if os(iOS)
        UIApplication.shared.open(appstoreURL)
#else
        NSWorkspace.shared.open(appstoreURL)
#endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
          exit(0)
        })
        return .none
        
      case .optionalUpdateRequired:
        return .none
      }
      
    case .optionalUpdateConfirmDismissed:
      state.optionalUpdateConfirm = nil
      return .none
      
    case .optionalUpdateConfirmTapped:
      guard let appVersionState = state.appVersionState else { return .none }
      
      switch appVersionState {
      case .success:
        return .none
      case .forcedUpdateRequired:
        return .none
      case .optionalUpdateRequired(message: _, appstoreURL: let appstoreURL):
#if os(iOS)
        UIApplication.shared.open(appstoreURL)
#else
        NSWorkspace.shared.open(appstoreURL)
#endif
        return .none
      }
      
    case .fetchedAppVersionState(let appVersionState):
      state.appVersionState = appVersionState
      
      switch appVersionState {
      case .success:
        state.isSuccess = true
        return .none
        
      case .forcedUpdateRequired(message: let message, appstoreURL: _):
        state.forceUpdateAlert = AlertState {
          TextState(Bundle.main.displayName)
        } message: {
          TextState(message)
        }
        return .none
        
      case .optionalUpdateRequired(message: let message, appstoreURL: let appstoreURL):
        state.isSuccess = true
        state.optionalUpdateConfirm = ConfirmationDialogState(title: {
          TextState(Bundle.main.displayName)
        }, actions: {
            .default(TextState("Update"), action: .send(.optionalUpdateConfirmTapped(appStoreURL: appstoreURL)))
        }, message: {
          TextState(message)
        })
      
        return .none
      }
      
    case .showFetchErrorAlert(errorMessage: let errorMessage):
      state.fetchErrorAlert = AlertState {
        TextState(Bundle.main.displayName)
      } message: {
        TextState(errorMessage)
      }
      return .none
      
    case .fetchErrorAlertDismissed:
      state.fetchErrorAlert = nil
      return .none
    }
  }
}
