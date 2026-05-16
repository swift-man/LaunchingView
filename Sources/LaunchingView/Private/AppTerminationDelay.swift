//
//  AppTerminationDelay.swift
//
//
//  Created by SwiftMan on 2026/05/17.
//

import Dependencies
import Foundation

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppTerminationDelay: Sendable {
  var sleep: @Sendable () async -> Void

  func callAsFunction() async {
    await sleep()
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private enum AppTerminationDelayKey: DependencyKey {
  static let liveValue = AppTerminationDelay {
    try? await Task.sleep(nanoseconds: 200_000_000)
  }

  static let testValue = AppTerminationDelay {
    let sleep: @Sendable () -> Void = unimplemented(#"@Dependency(\.appTerminationDelay)"#)
    sleep()
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DependencyValues {
  var appTerminationDelay: AppTerminationDelay {
    get { self[AppTerminationDelayKey.self] }
    set { self[AppTerminationDelayKey.self] = newValue }
  }
}
