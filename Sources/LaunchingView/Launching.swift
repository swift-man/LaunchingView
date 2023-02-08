//
//  Launching.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import LaunchingService
import ComposableArchitecture
import SwiftUI

public struct Launching: ReducerProtocol {
  // MARK: - Enums
  public struct State: Equatable {
    var appUpdateState: AppUpdateStatus?
    var appUpdateFetchErrorAlert: AlertState<Action>?
    var forceUpdateAlert: AlertState<Action>?
    var isValid = false
    var optionalUpdateConfirm: ConfirmationDialogState<Action>?
    let optionalUpdateDoneText: TextState
    
    public init(optionalUpdateDoneText: TextState = TextState("Update")) {
      self.optionalUpdateDoneText = optionalUpdateDoneText
    }
  }
  
  public enum Action: Equatable {
    case fetchAppUpdateState
    case appUpdateFetchErrorAlertDismissed
    case setAppUpdateState(AppUpdateStatus)
    case forceUpdateAlertDismissed
    case optionalUpdateConfirmDismissed
    case optionalUpdateConfirmTapped(appStoreURL: URL?)
    case showFetchErrorAlert(errorMessage: String)
  }
  
  let launchingInteractor: LaunchingInteractable
  
  public init(launchingInteractor: LaunchingInteractable) {
    self.launchingInteractor = launchingInteractor
  }
  
  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .fetchAppUpdateState:
      return .task {
        do {
          let state = try await launchingInteractor.fetchLaunchingConfig()
          return .setAppUpdateState(state)
        } catch {
          return .showFetchErrorAlert(errorMessage: error.localizedDescription)
        }
      }
    case .forceUpdateAlertDismissed:
      guard let appUpdateState = state.appUpdateState else { return .none }
      
      switch appUpdateState {
      case .valid, .optionalUpdateRequired:
        return .none
      case .forcedUpdateRequired(message: _, appstoreURL: let appstoreURL):
        SharedURL.shared.open(appstoreURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
          exit(0)
        })
        return .none
      }
      
    case .optionalUpdateConfirmDismissed:
      state.optionalUpdateConfirm = nil
      return .none
      
    case .optionalUpdateConfirmTapped:
      guard let appUpdateState = state.appUpdateState else { return .none }
      
      switch appUpdateState {
      case .valid, .forcedUpdateRequired:
        return .none
      case .optionalUpdateRequired(message: _, appstoreURL: let appstoreURL):
        SharedURL.shared.open(appstoreURL)
        return .none
      }
      
    case .setAppUpdateState(let appVersionState):
      state.appUpdateState = appVersionState
      
      switch appVersionState {
      case .valid:
        state.isValid = true
        return .none
        
      case .forcedUpdateRequired(message: let message, appstoreURL: _):
        state.forceUpdateAlert = AlertState {
          TextState(Bundle.main.displayName)
        } message: {
          TextState(message)
        }
        return .none
        
      case .optionalUpdateRequired(message: let message, appstoreURL: let appstoreURL):
        state.isValid = true
        state.optionalUpdateConfirm = ConfirmationDialogState(title: {
          TextState(Bundle.main.displayName)
        }, actions: {
          .default(state.optionalUpdateDoneText, action: .send(.optionalUpdateConfirmTapped(appStoreURL: appstoreURL)))
        }, message: {
          TextState(message)
        })
        
        return .none
      }
      
    case .showFetchErrorAlert(errorMessage: let errorMessage):
      state.appUpdateFetchErrorAlert = AlertState {
        TextState(Bundle.main.displayName)
      } message: {
        TextState(errorMessage)
      }
      return .none
      
    case .appUpdateFetchErrorAlertDismissed:
      state.appUpdateFetchErrorAlert = nil
      return .none
    }
  }
}
