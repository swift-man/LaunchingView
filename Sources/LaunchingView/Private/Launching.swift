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
struct Launching: ReducerProtocol {
  // MARK: - Enums
  struct State: Equatable {
    var appUpdateState: AppUpdateStatus?
    
    
    /// ContentView Display
    var displayContentView = false
    
    var appUpdateFetchErrorAlert: AlertState<Action>?
    
    var forceUpdateAlert: AlertState<Action>?
    
    var optionalUpdateAlert: AlertState<Action>?
    
    var noticeAlert: AlertState<Action>?
  }
  
  enum Action: Equatable {
    
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
    case optionalUpdateAlertDismissed
    
    /// 선택 업데이트 얼럿의 `업데이트`를 유저가 선택 시 호출
    case optionalUpdateAlertDoneTapped(appStoreURL: URL?)
    
    /// Action.fetchAppUpdateState 실패하면 Error Alert를 호출
    case showFetchErrorAlert(errorMessage: String)
    
    /// 공지 얼럿 Dismissed 시 호출
    case noticeAlertDismissed
  }
  
  @Dependency(\.launchingService)
  var launchingService
  
  @Dependency(\.launchingAlertDefaultText)
  var launchingAlertDefaultText
  
  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .fetchAppUpdateState:
      return .task {
        do {
          let state = try await launchingService.fetchAppUpdateStatus()
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
        SharedURL.shared.open(updateAlert.alertDoneLinkURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
          exit(0)
        })
        return .none
      }
      
    case .optionalUpdateAlertDismissed:
      state.optionalUpdateAlert = nil
      return .none
      
    case .optionalUpdateAlertDoneTapped:
      guard let appUpdateState = state.appUpdateState else { return .none }
      
      switch appUpdateState {
      case .valid, .forcedUpdateRequired, .notice:
        return .none
        
      case .optionalUpdateRequired(let updateAlert):
        SharedURL.shared.open(updateAlert.alertDoneLinkURL)
        return .none
      }
      
    case .setAppUpdateState(let appVersionState):
      state.appUpdateState = appVersionState
      
      switch appVersionState {
      case .valid:
        state.displayContentView = true
        return .none
        
      case .forcedUpdateRequired(let updateAlert):
        let title = !updateAlert.title.isEmpty ? updateAlert.title : launchingAlertDefaultText.forceUpdate.title
        let message = !updateAlert.message.isEmpty ? updateAlert.message : launchingAlertDefaultText.forceUpdate.message
        
        state.forceUpdateAlert = AlertState {
          TextState(title)
        } message: {
          TextState(message)
        }
        return .none
        
      case .optionalUpdateRequired(let updateAlert):
        let title = !updateAlert.title.isEmpty ? updateAlert.title : launchingAlertDefaultText.optionalUpdate.title
        let message = !updateAlert.message.isEmpty ? updateAlert.message : launchingAlertDefaultText.optionalUpdate.message
        
        state.displayContentView = true
        state.optionalUpdateAlert = AlertState(
          title: TextState(title),
          message: TextState(message),
          primaryButton: .cancel(TextState(launchingAlertDefaultText.optionalUpdate.cancel)),
          secondaryButton: .default(TextState(launchingAlertDefaultText.optionalUpdate.done),
                                    action: .send(.optionalUpdateAlertDoneTapped(appStoreURL: updateAlert.alertDoneLinkURL)))
        )
        
        return .none
        
      case .notice(let noticeAlert):
        let title = !noticeAlert.title.isEmpty ? noticeAlert.title : launchingAlertDefaultText.notice.title
        let message = !noticeAlert.message.isEmpty ? noticeAlert.message : launchingAlertDefaultText.notice.message
        
        if !noticeAlert.isAppTerminated {
          state.displayContentView = true
        }
        
        state.noticeAlert = AlertState {
          TextState(title)
        } message: {
          TextState(message)
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
