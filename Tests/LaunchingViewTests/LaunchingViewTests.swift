import ComposableArchitecture
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
    store.dependencies.appTerminator = AppTerminator {
      await recorder.terminate()
    }

    await store.send(.optionalUpdateAlertDoneTapped(appStoreURL: actionURL)).finish()

    #expect(await recorder.openedURLs() == [actionURL])
    #expect(await recorder.terminateCount() == 0)
  }

  @Test
  func forceUpdateDismissalOpensURLAndTerminatesApp() async {
    let url = URL(string: "https://example.com/force")!
    let recorder = ExternalActionRecorder()
    let store = TestStore(
      initialState: Launching.State(
        appUpdateStatus: .forcedUpdateRequired(
          UpdateAlert(
            title: "",
            message: "",
            alertDoneLinkURL: url
          )
        )
      ),
      reducer: Launching()
    )
    store.dependencies.openURL = OpenURLEffect { url in
      await recorder.open(url)
      return true
    }
    store.dependencies.appTerminator = AppTerminator {
      await recorder.terminate()
    }

    await store.send(.forceUpdateAlertDismissed).finish()

    #expect(await recorder.openedURLs() == [url])
    #expect(await recorder.terminateCount() == 1)
  }

  @Test
  func terminatingNoticeDismissalOpensURLAndTerminatesApp() async {
    let url = URL(string: "https://example.com/notice")!
    let recorder = ExternalActionRecorder()
    let store = TestStore(
      initialState: Launching.State(
        appUpdateStatus: .notice(
          NoticeAlert(
            title: "",
            message: "",
            isAppTerminated: true,
            doneURL: url
          )
        )
      ),
      reducer: Launching()
    )
    store.dependencies.openURL = OpenURLEffect { url in
      await recorder.open(url)
      return true
    }
    store.dependencies.appTerminator = AppTerminator {
      await recorder.terminate()
    }

    await store.send(.noticeAlertDismissed).finish()

    #expect(await recorder.openedURLs() == [url])
    #expect(await recorder.terminateCount() == 1)
  }
}

private actor ExternalActionRecorder {
  private var urls: [URL] = []
  private var terminations = 0

  func open(_ url: URL) {
    urls.append(url)
  }

  func terminate() {
    terminations += 1
  }

  func openedURLs() -> [URL] {
    urls
  }

  func terminateCount() -> Int {
    terminations
  }
}
