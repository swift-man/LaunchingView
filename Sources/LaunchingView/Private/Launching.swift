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
struct Launching: Reducer {
  // MARK: - Enums
  @ObservableState
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
    
    @Presents var appUpdateFetchErrorAlert: AlertState<Action.AppUpdateFetchErrorAlert>?
    
    @Presents var optionalUpdateAlert: AlertState<Action.OptionalUpdateAlert>?
    
    @Presents var noticeAlert: AlertState<Action.NoticeAlert>?

    var blockingAlert: BlockingAlert?
  }
  
  @CasePathable
  enum Action: Equatable {
    @CasePathable
    enum AppUpdateFetchErrorAlert: Equatable {}

    @CasePathable
    enum OptionalUpdateAlert: Equatable {
      case doneTapped(appStoreURL: URL?)
    }

    @CasePathable
    enum NoticeAlert: Equatable {}

    case appUpdateFetchErrorAlert(PresentationAction<AppUpdateFetchErrorAlert>)

    case optionalUpdateAlert(PresentationAction<OptionalUpdateAlert>)

    case noticeAlert(PresentationAction<NoticeAlert>)
    
    /// AppUpdateStatus 를 Firebase.RemoteConfig 를 통해 가져옵니다.
    case fetchAppUpdateStatus
    
    /// Action.fetchAppUpdateStatus 취소 시 호출되며 진행 상태를 정리합니다.
    case fetchAppUpdateStatusCancelled
    
    /// Action.fetchAppUpdateStatus 를 통해 AppUpdateStatus 를 세팅합니다.
    case setAppUpdateStatus(AppUpdateStatus)
    
    /// 차단 화면의 버튼 선택 시 호출
    case blockingAlertButtonTapped(linkURL: URL?)
    
    /// Action.fetchAppUpdateState 실패하면 Error Alert를 호출
    case showFetchErrorAlert(errorMessage: String)
  }
  
  @Dependency(\.launchingService)
  var launchingService
  
  @Dependency(\.launchingAlertDefaultText)
  var launchingAlertDefaultText

  @Dependency(\.openURL)
  var openURL
  
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .fetchAppUpdateStatus:
      guard !state.isFetching else {
        state.hasPendingFetch = true
        return .none
      }
      
      state.isFetching = true
      let launchingService = self.launchingService
      return .run { send in
        do {
          let appStatus = try await launchingService.fetchAppUpdateStatus()
          await send(.setAppUpdateStatus(appStatus))
        } catch is CancellationError {
          await send(.fetchAppUpdateStatusCancelled)
        } catch {
          await send(.showFetchErrorAlert(errorMessage: error.localizedDescription))
        }
      }

    case .fetchAppUpdateStatusCancelled:
      state.isFetching = false
      let hasPendingFetch = state.hasPendingFetch
      state.hasPendingFetch = false
      return fetchAgainIfNeeded(hasPendingFetch)

    case .blockingAlertButtonTapped(let linkURL):
      return openExternalURL(linkURL)

    case .optionalUpdateAlert(.presented(.doneTapped(let appStoreURL))):
      state.optionalUpdateAlert = nil

      switch state.appUpdateStatus {
      case .valid, .forcedUpdateRequired, .notice, nil:
        return .none
        
      case .optionalUpdateRequired:
        return openExternalURL(appStoreURL)
      }

    case .optionalUpdateAlert(.dismiss):
      state.optionalUpdateAlert = nil
      return .none

    case .optionalUpdateAlert:
      return .none
      
    case .setAppUpdateStatus(let appVersionStatus):
      state.isFetching = false
      let hasPendingFetch = state.hasPendingFetch
      state.hasPendingFetch = false
      state.appUpdateStatus = appVersionStatus
      state.appUpdateFetchErrorAlert = nil
      
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
        state.optionalUpdateAlert = AlertState {
          TextState(title)
        } actions: {
          ButtonState(role: .cancel) {
            TextState(launchingAlertDefaultText.optionalUpdate.cancel)
          }
          ButtonState(action: .doneTapped(appStoreURL: updateAlert.alertDoneLinkURL)) {
            TextState(launchingAlertDefaultText.optionalUpdate.done)
          }
        } message: {
          TextState(message)
        }
        
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
      
      state.optionalUpdateAlert = nil
      state.noticeAlert = nil
      state.appUpdateFetchErrorAlert = AlertState {
        TextState(Bundle.main.displayName)
      } message: {
        TextState(errorMessage)
      }
      return .none
      
    case .appUpdateFetchErrorAlert(.dismiss):
      state.appUpdateFetchErrorAlert = nil
      return .send(.fetchAppUpdateStatus)

    case .appUpdateFetchErrorAlert:
      return .none

    case .noticeAlert(.dismiss):
      state.noticeAlert = nil
      
      guard let appUpdateStatus = state.appUpdateStatus else { return .none }
      
      switch appUpdateStatus {
      case .valid, .forcedUpdateRequired, .optionalUpdateRequired:
        return .none
        
      case .notice(let noticeAlert):
        guard !noticeAlert.isAppTerminated else { return .none }
        return openExternalURL(noticeAlert.doneURL)
      }

    case .noticeAlert:
      return .none
    }
  }

  private func openExternalURL(_ url: URL?) -> Effect<Action> {
    guard let url else { return .none }

    let openURL = self.openURL

    return .run { _ in
      await openURL(url)
    }
  }

  private func fetchAgainIfNeeded(_ hasPendingFetch: Bool) -> Effect<Action> {
    hasPendingFetch ? .send(.fetchAppUpdateStatus) : .none
  }
}
