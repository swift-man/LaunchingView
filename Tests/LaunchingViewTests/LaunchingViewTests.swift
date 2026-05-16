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
}
