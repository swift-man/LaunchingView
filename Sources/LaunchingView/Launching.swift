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
    var isValid = false
    
    var appUpdateFetchErrorAlert: AlertState<Action>?
    
    var forceUpdateAlert: AlertState<Action>?
    
    var optionalUpdateConfirm: ConfirmationDialogState<Action>?
    let optionalUpdateDoneText: TextState
    
    var noticeAlert: AlertState<Action>?
    
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
    
    /// 공지 얼럿 Dismissed 시 호출
    case noticeAlertDismissed
  }
  
  @Dependency(\.launchingService)
  var launchingService
  
  /// make instance
  /// - Parameters
  ///   - launchingInteractor: `LaunchingService` instance
  public init() {
  }
  
  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .fetchAppUpdateState:
      return .task {
        do {
          let state = try await launchingService.fetchAppUpdateStatus(keyStore: LaunchingServiceKeyStore())
          return .setAppUpdateState(state)
        } catch {
          return .showFetchErrorAlert(errorMessage: error.localizedDescription)
        }
      }
    case .forceUpdateAlertDismissed:
      guard let appUpdateState = state.appUpdateState else { return .none }
      
      switch appUpdateState {
      case .valid, .optionalUpdateRequired, .notice:
        return .none
        
      case .forcedUpdateRequired(let updateAlert):
        SharedURL.shared.open(updateAlert.appstoreURL)
        
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
      case .valid, .forcedUpdateRequired, .notice:
        return .none
        
      case .optionalUpdateRequired(let updateAlert):
        SharedURL.shared.open(updateAlert.appstoreURL)
        return .none
      }
      
    case .setAppUpdateState(let appVersionState):
      state.appUpdateState = appVersionState
      
      switch appVersionState {
      case .valid:
        state.isValid = true
        return .none
        
      case .forcedUpdateRequired(let updateAlert):
        state.forceUpdateAlert = AlertState {
          TextState(Bundle.main.displayName)
        } message: {
          TextState(updateAlert.message)
        }
        return .none
        
      case .optionalUpdateRequired(let updateAlert):
        state.isValid = true
        state.optionalUpdateConfirm = ConfirmationDialogState(title: {
          TextState(Bundle.main.displayName)
        }, actions: {
          .default(state.optionalUpdateDoneText, action: .send(.optionalUpdateConfirmTapped(appStoreURL: updateAlert.appstoreURL)))
        }, message: {
          TextState(updateAlert.message)
        })
        
        return .none
        
      case .notice(let noticeAlert):
        if !noticeAlert.isAppTerminated {
          state.isValid = true
        }
        
        state.noticeAlert = AlertState {
          TextState(noticeAlert.title)
        } message: {
          TextState(noticeAlert.message)
        }
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
      
    case .noticeAlertDismissed:
      state.noticeAlert = nil
      
      guard let appUpdateState = state.appUpdateState else { return .none }
      
      switch appUpdateState {
      case .valid, .forcedUpdateRequired, .optionalUpdateRequired:
        return .none
        
      case .notice(let noticeAlert):
        if let url = noticeAlert.doneURL {
          SharedURL.shared.open(url)
        }
        
        if noticeAlert.isAppTerminated {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            exit(0)
          })
        }
        return .none
      }
    }
  }
}
