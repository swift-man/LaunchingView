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
      ),
      reducer: Launching()
    )
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
      initialState: Launching.State(displayContentView: true),
      reducer: Launching()
    )
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
      initialState: Launching.State(displayContentView: true),
      reducer: Launching()
    )
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
  func fetchWhileFetchingMarksPendingRefresh() {
    let url = URL(string: "https://example.com/force")!
    let forceStatus = AppUpdateStatus.forcedUpdateRequired(
      UpdateAlert(
        title: "Force update",
        message: "Please update now",
        alertDoneLinkURL: url
      )
    )
    var state = Launching.State(isFetching: true)
    let reducer = Launching()

    _ = reducer.reduce(into: &state, action: .fetchAppUpdateStatus)

    #expect(state.hasPendingFetch)

    withDependencies {
      $0.launchingAlertDefaultText = LaunchingAlertDefaultText(
        forceUpdate: .init(done: "Update")
      )
    } operation: {
      _ = reducer.reduce(into: &state, action: .setAppUpdateStatus(forceStatus))
    }

    #expect(!state.isFetching)
    #expect(!state.hasPendingFetch)
    #expect(state.appUpdateStatus == forceStatus)
    #expect(state.displayContentView == false)
    #expect(
      state.blockingAlert == Launching.State.BlockingAlert(
        title: "Force update",
        message: "Please update now",
        buttonTitle: "Update",
        linkURL: url
      )
    )
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
