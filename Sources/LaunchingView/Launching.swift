//
//  Launching.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import LaunchingService
import ComposableArchitecture
import SwiftUI

/// Launching은 App 구동을 위한 Request 를 포함한 AppUpdate 상태를 관리합니다.
public struct Launching: ReducerProtocol {
  // MARK: - Enums
  public struct State: Equatable {
    var appUpdateState: AppUpdateStatus?
    var appUpdateFetchErrorAlert: AlertState<Action>?
    var forceUpdateAlert: AlertState<Action>?
    var isValid = false
    var optionalUpdateConfirm: ConfirmationDialogState<Action>?
    let optionalUpdateDoneText: TextState
    
    /// Launching.State 생성
    /// - Parameter optionalUpdateDoneText: 선택 업데이트 Alert 에서 `업데이트` 버튼의 Title을 변경합니다.
    public init(optionalUpdateDoneText: TextState = TextState("Update")) {
      self.optionalUpdateDoneText = optionalUpdateDoneText
    }
  }
  
  public enum Action: Equatable {
    
    /// AppUpdateState 를 Firebase.RemoteConfig 를 통해 가져옵니다.
    case fetchAppUpdateState
    
    /// Action.fetchAppUpdateState 실패 후 Error 얼럿 Dismissed 시 호출되며
    /// Action.fetchAppUpdateState 가 다시 호출 됩니다.
    case appUpdateFetchErrorAlertDismissed
    
    /// Action.fetchAppUpdateState 를 통해 AppUpdateStatus 를 세팅합니다.
    case setAppUpdateState(AppUpdateStatus)
    
    /// 강제 업데이트 얼럿 Dismissed 시 호출
    case forceUpdateAlertDismissed
    
    /// 선택 업데이트 얼럿 Dismissed 시 호출
    case optionalUpdateConfirmDismissed
    
    /// 선택 업데이트 얼럿의 `업데이트`를 유저가 선택 시 호출
    case optionalUpdateConfirmTapped(appStoreURL: URL?)
    
    /// Action.fetchAppUpdateState 실패하면 Error Alert를 호출
    case showFetchErrorAlert(errorMessage: String)
  }
  
  private let launchingInteractor: LaunchingInteractable
  
  /// make instance
  /// - Parameters
  ///   - launchingInteractor: `LaunchingService` instance
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
      return .send(.fetchAppUpdateState)
    }
  }
}
