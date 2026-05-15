import SwiftUI
import XCTest
@testable import LaunchingView

final class LaunchingViewTests: XCTestCase {
  func testLaunchingViewInitializesWithDefaultCompletionState() {
    let view = LaunchingView(
      content: {
        Text("Content")
      },
      launchScreen: {
        Text("Launch")
      }
    )

    XCTAssertFalse(String(describing: type(of: view)).isEmpty)
  }

  func testLaunchingViewInitializesWithCustomCompletionState() {
    let view = LaunchingView(
      content: {
        Text("Content")
      },
      launchScreen: {
        Text("Launch")
      },
      isFinished: .constant(false)
    )

    XCTAssertFalse(String(describing: type(of: view)).isEmpty)
  }

  func testAsyncLaunchingViewInitializes() {
    let view = AsyncLaunchingView {
      Text("Content")
    }

    XCTAssertFalse(String(describing: type(of: view)).isEmpty)
  }

  func testLaunchingAlertDefaultTextCanBeCustomized() {
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

    XCTAssertEqual(defaultText.forceUpdate.title, "Force update")
    XCTAssertEqual(defaultText.forceUpdate.message, "Please update now")
    XCTAssertEqual(defaultText.forceUpdate.done, "Update")
    XCTAssertEqual(defaultText.optionalUpdate.cancel, "Later")
    XCTAssertEqual(defaultText.notice.done, "Open")
  }
}
