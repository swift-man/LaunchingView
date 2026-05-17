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
    struct BlockingAlert: Equatable {
      var title: String
      var message: String
      var buttonTitle: String
      var linkURL: URL?
    }

    var appUpdateStatus: AppUpdateStatus?
    
    var isFetching = false

    var hasPendingFetch = false
    
    /// ContentView Display
    var displayContentView = false
    
    var appUpdateFetchErrorAlert: AlertState<Action>?
    
    var optionalUpdateAlert: AlertState<Action>?
    
    var noticeAlert: AlertState<Action>?

    var blockingAlert: BlockingAlert?
  }
  
  enum Action: Equatable {
    
    /// AppUpdateStatus 를 Firebase.RemoteConfig 를 통해 가져옵니다.
    case fetchAppUpdateStatus
    
    /// Action.fetchAppUpdateStatus 실패 후 Error 얼럿 Dismissed 시 호출되며
    /// Action.fetchAppUpdateStatus 가 다시 호출 됩니다.
    case appUpdateFetchErrorAlertDismissed
    
    /// Action.fetchAppUpdateStatus 를 통해 AppUpdateStatus 를 세팅합니다.
    case setAppUpdateStatus(AppUpdateStatus)
    
    /// 차단 화면의 버튼 선택 시 호출
    case blockingAlertButtonTapped(linkURL: URL?)
    
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

  @Dependency(\.openURL)
  var openURL
  
  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .fetchAppUpdateStatus:
      guard !state.isFetching else {
        state.hasPendingFetch = true
        return .none
      }
      
      state.isFetching = true
      return .task {
        do {
          let appStatus = try await launchingService.fetchAppUpdateStatus()
          return .setAppUpdateStatus(appStatus)
        } catch {
          return .showFetchErrorAlert(errorMessage: error.localizedDescription)
        }
      }

    case .blockingAlertButtonTapped(let linkURL):
      return openExternalURL(linkURL)
      
    case .optionalUpdateAlertDismissed:
      state.optionalUpdateAlert = nil
      return .none
      
    case .optionalUpdateAlertDoneTapped(let appStoreURL):
      switch state.appUpdateStatus {
      case .valid, .forcedUpdateRequired, .notice, nil:
        return .none
        
      case .optionalUpdateRequired:
        return openExternalURL(appStoreURL)
      }
      
    case .setAppUpdateStatus(let appVersionStatus):
      state.isFetching = false
      let hasPendingFetch = state.hasPendingFetch
      state.hasPendingFetch = false
      state.appUpdateStatus = appVersionStatus
      
      switch appVersionStatus {
      case .valid:
        state.displayContentView = true
        state.blockingAlert = nil
        state.optionalUpdateAlert = nil
        state.noticeAlert = nil
        return fetchAgainIfNeeded(hasPendingFetch)
        
      case .forcedUpdateRequired(let updateAlert):
        let title = !updateAlert.title.isEmpty ? updateAlert.title : launchingAlertDefaultText.forceUpdate.title
        let message = !updateAlert.message.isEmpty ? updateAlert.message : launchingAlertDefaultText.forceUpdate.message

        state.displayContentView = false
        state.optionalUpdateAlert = nil
        state.noticeAlert = nil
        state.blockingAlert = State.BlockingAlert(
          title: title,
          message: message,
          buttonTitle: launchingAlertDefaultText.forceUpdate.done,
          linkURL: updateAlert.alertDoneLinkURL
        )
        return fetchAgainIfNeeded(hasPendingFetch)
        
      case .optionalUpdateRequired(let updateAlert):
        let title = !updateAlert.title.isEmpty ? updateAlert.title : launchingAlertDefaultText.optionalUpdate.title
        let message = !updateAlert.message.isEmpty ? updateAlert.message : launchingAlertDefaultText.optionalUpdate.message
        
        state.displayContentView = true
        state.blockingAlert = nil
        state.noticeAlert = nil
        state.optionalUpdateAlert = AlertState(
          title: TextState(title),
          message: TextState(message),
          primaryButton: .cancel(TextState(launchingAlertDefaultText.optionalUpdate.cancel)),
          secondaryButton: .default(TextState(launchingAlertDefaultText.optionalUpdate.done),
                                    action: .send(.optionalUpdateAlertDoneTapped(appStoreURL: updateAlert.alertDoneLinkURL)))
        )
        
        return fetchAgainIfNeeded(hasPendingFetch)
        
      case .notice(let noticeAlert):
        let title = !noticeAlert.title.isEmpty ? noticeAlert.title : launchingAlertDefaultText.notice.title
        let message = !noticeAlert.message.isEmpty ? noticeAlert.message : launchingAlertDefaultText.notice.message
        state.optionalUpdateAlert = nil
        
        if noticeAlert.isAppTerminated {
          state.displayContentView = false
          state.noticeAlert = nil
          state.blockingAlert = State.BlockingAlert(
            title: title,
            message: message,
            buttonTitle: launchingAlertDefaultText.notice.done,
            linkURL: noticeAlert.doneURL
          )
        } else {
          state.displayContentView = true
          state.blockingAlert = nil
          state.noticeAlert = AlertState {
            TextState(title)
          } message: {
            TextState(message)
          }
        }
        return fetchAgainIfNeeded(hasPendingFetch)
      }
      
    case .showFetchErrorAlert(errorMessage: let errorMessage):
      state.isFetching = false
      let hasPendingFetch = state.hasPendingFetch
      state.hasPendingFetch = false

      guard !hasPendingFetch else {
        return .send(.fetchAppUpdateStatus)
      }
      
      state.appUpdateFetchErrorAlert = AlertState {
        TextState(Bundle.main.displayName)
      } message: {
        TextState(errorMessage)
      }
      return .none
      
    case .appUpdateFetchErrorAlertDismissed:
      state.appUpdateFetchErrorAlert = nil
      return .send(.fetchAppUpdateStatus)
      
    case .noticeAlertDismissed:
      state.noticeAlert = nil
      
      guard let appUpdateStatus = state.appUpdateStatus else { return .none }
      
      switch appUpdateStatus {
      case .valid, .forcedUpdateRequired, .optionalUpdateRequired:
        return .none
        
      case .notice(let noticeAlert):
        guard !noticeAlert.isAppTerminated else { return .none }
        return openExternalURL(noticeAlert.doneURL)
      }
    }
  }

  private func openExternalURL(_ url: URL?) -> EffectTask<Action> {
    guard let url else { return .none }

    let openURL = self.openURL

    return .run { _ in
      await openURL(url)
    }
  }

  private func fetchAgainIfNeeded(_ hasPendingFetch: Bool) -> EffectTask<Action> {
    hasPendingFetch ? .send(.fetchAppUpdateStatus) : .none
  }
}
