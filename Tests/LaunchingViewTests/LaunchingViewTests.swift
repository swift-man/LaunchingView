import ComposableArchitecture
import Foundation
import LaunchingService
import SwiftUI
import Testing
@testable import LaunchingView

@Suite("LaunchingView")
@MainActor
struct LaunchingViewTests {
  @Test
  func launchingViewInitializesWithDefaultCompletionState() {
    let view = LaunchingView(
      content: {
        Text("Content")
      },
      launchScreen: {
        Text("Launch")
      }
    )

    #expect(!String(describing: type(of: view)).isEmpty)
  }

  @Test
  func launchingViewInitializesWithCustomCompletionState() {
    let view = LaunchingView(
      content: {
        Text("Content")
      },
      launchScreen: {
        Text("Launch")
      },
      isFinished: .constant(false)
    )

    #expect(!String(describing: type(of: view)).isEmpty)
  }

  @Test
  func asyncLaunchingViewInitializes() {
    let view = AsyncLaunchingView {
      Text("Content")
    }

    #expect(!String(describing: type(of: view)).isEmpty)
  }

  @Test
  func launchingAlertDefaultTextCanBeCustomized() {
    let defaultText = LaunchingAlertDefaultText(
      forceUpdate: .init(
        title: "Force update",
        message: "Please update now",
        done: "Update"
      ),
      optionalUpdate: .init(
        title: "Optional update",
        message: "A new version is available",
        cancel: "Later",
        done: "Update"
      ),
      notice: .init(
        title: "Notice",
        message: "Hello",
        cancel: "Close",
        done: "Open"
      )
    )

    #expect(defaultText.forceUpdate.title == "Force update")
    #expect(defaultText.forceUpdate.message == "Please update now")
    #expect(defaultText.forceUpdate.done == "Update")
    #expect(defaultText.optionalUpdate.cancel == "Later")
    #expect(defaultText.notice.done == "Open")
  }

  @Test
  func optionalUpdateDoneOpensActionURL() async {
    let stateURL = URL(string: "https://example.com/state-optional")!
    let actionURL = URL(string: "https://example.com/action-optional")!
    let recorder = ExternalActionRecorder()
    let store = TestStore(
      initialState: Launching.State(
        appUpdateStatus: .optionalUpdateRequired(
          UpdateAlert(
            title: "",
            message: "",
            alertDoneLinkURL: stateURL
          )
        )
      )
    ) {
      Launching()
    }
    store.dependencies.openURL = OpenURLEffect { url in
      await recorder.open(url)
      return true
    }

    await store.send(.optionalUpdateAlertDoneTapped(appStoreURL: actionURL)).finish()

    #expect(await recorder.openedURLs() == [actionURL])
  }

  @Test
  func forceUpdateShowsBlockingViewAndOpensURL() async {
    let url = URL(string: "https://example.com/force")!
    let status = AppUpdateStatus.forcedUpdateRequired(
      UpdateAlert(
        title: "Force update",
        message: "Please update now",
        alertDoneLinkURL: url
      )
    )
    let recorder = ExternalActionRecorder()
    let store = TestStore(
      initialState: Launching.State(displayContentView: true)
    ) {
      Launching()
    }
    store.dependencies.launchingAlertDefaultText = LaunchingAlertDefaultText(
      forceUpdate: .init(done: "Update")
    )
    store.dependencies.openURL = OpenURLEffect { url in
      await recorder.open(url)
      return true
    }

    await store.send(.setAppUpdateStatus(status)) {
      $0.appUpdateStatus = status
      $0.displayContentView = false
      $0.blockingAlert = Launching.State.BlockingAlert(
        title: "Force update",
        message: "Please update now",
        buttonTitle: "Update",
        linkURL: url
      )
    }.finish()

    await store.send(.blockingAlertButtonTapped(linkURL: url)).finish()

    #expect(await recorder.openedURLs() == [url])
  }

  @Test
  func terminatingNoticeShowsBlockingViewAndOpensURL() async {
    let url = URL(string: "https://example.com/notice")!
    let status = AppUpdateStatus.notice(
      NoticeAlert(
        title: "Notice",
        message: "Please read",
        isAppTerminated: true,
        doneURL: url
      )
    )
    let recorder = ExternalActionRecorder()
    let store = TestStore(
      initialState: Launching.State(displayContentView: true)
    ) {
      Launching()
    }
    store.dependencies.launchingAlertDefaultText = LaunchingAlertDefaultText(
      notice: .init(done: "Open")
    )
    store.dependencies.openURL = OpenURLEffect { url in
      await recorder.open(url)
      return true
    }

    await store.send(.setAppUpdateStatus(status)) {
      $0.appUpdateStatus = status
      $0.displayContentView = false
      $0.blockingAlert = Launching.State.BlockingAlert(
        title: "Notice",
        message: "Please read",
        buttonTitle: "Open",
        linkURL: url
      )
    }.finish()

    await store.send(.blockingAlertButtonTapped(linkURL: url)).finish()

    #expect(await recorder.openedURLs() == [url])
  }

  @Test
  func fetchErrorClearsOtherAlertStates() async {
    let store = TestStore(
      initialState: Launching.State(
        optionalUpdateAlert: AlertState {
          TextState("Optional update")
        },
        noticeAlert: AlertState {
          TextState("Notice")
        }
      )
    ) {
      Launching()
    }

    await store.send(.showFetchErrorAlert(errorMessage: "Network failed")) {
      $0.optionalUpdateAlert = nil
      $0.noticeAlert = nil
      $0.appUpdateFetchErrorAlert = AlertState {
        TextState(Bundle.main.displayName)
      } message: {
        TextState("Network failed")
      }
    }
  }

  @Test
  func fetchCancellationClearsFetchingWithoutShowingAlert() async {
    let store = TestStore(
      initialState: Launching.State()
    ) {
      Launching()
    }
    store.dependencies.launchingService = CancellingLaunchingService()

    await store.send(.fetchAppUpdateStatus) {
      $0.isFetching = true
    }

    await store.receive(.fetchAppUpdateStatusCancelled) {
      $0.isFetching = false
    }
  }

  @Test
  func fetchWhileFetchingRefreshesAgainAfterCurrentStatusFinishes() async {
    let url = URL(string: "https://example.com/force")!
    let forceStatus = AppUpdateStatus.forcedUpdateRequired(
      UpdateAlert(
        title: "Force update",
        message: "Please update now",
        alertDoneLinkURL: url
      )
    )
    let store = TestStore(
      initialState: Launching.State(isFetching: true)
    ) {
      Launching()
    }
    store.dependencies.launchingAlertDefaultText = LaunchingAlertDefaultText(
      forceUpdate: .init(done: "Update")
    )
    store.dependencies.launchingService = StubLaunchingService(status: .valid)

    await store.send(.fetchAppUpdateStatus) {
      $0.hasPendingFetch = true
    }

    await store.send(.setAppUpdateStatus(forceStatus)) {
      $0.isFetching = false
      $0.hasPendingFetch = false
      $0.appUpdateStatus = forceStatus
      $0.displayContentView = false
      $0.blockingAlert = Launching.State.BlockingAlert(
        title: "Force update",
        message: "Please update now",
        buttonTitle: "Update",
        linkURL: url
      )
    }

    await store.receive(.fetchAppUpdateStatus) {
      $0.isFetching = true
    }

    await store.receive(.setAppUpdateStatus(.valid)) {
      $0.isFetching = false
      $0.appUpdateStatus = .valid
      $0.displayContentView = true
      $0.blockingAlert = nil
      $0.optionalUpdateAlert = nil
      $0.noticeAlert = nil
    }
  }
}

private final class StubLaunchingService: LaunchingInteractable {
  private let status: AppUpdateStatus

  init(status: AppUpdateStatus) {
    self.status = status
  }

  func fetchAppUpdateStatus() async throws -> AppUpdateStatus {
    status
  }
}

private final class CancellingLaunchingService: LaunchingInteractable {
  func fetchAppUpdateStatus() async throws -> AppUpdateStatus {
    throw CancellationError()
  }
}

private actor ExternalActionRecorder {
  private var urls: [URL] = []

  func open(_ url: URL) {
    urls.append(url)
  }

  func openedURLs() -> [URL] {
    urls
  }
}
