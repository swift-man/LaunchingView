//
//  AppTerminator.swift
//
//
//  Created by SwiftMan on 2026/05/17.
//

import Darwin
import Dependencies
import Foundation

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppTerminator: Sendable {
  var terminate: @Sendable () async -> Void

  func callAsFunction() async {
    await terminate()
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private enum AppTerminatorKey: DependencyKey {
  static let liveValue = AppTerminator {
    Darwin.exit(0)
  }

  static let testValue = AppTerminator {
    let terminate: @Sendable () -> Void = unimplemented(#"@Dependency(\.appTerminator)"#)
    terminate()
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DependencyValues {
  var appTerminator: AppTerminator {
    get { self[AppTerminatorKey.self] }
    set { self[AppTerminatorKey.self] = newValue }
  }
}
