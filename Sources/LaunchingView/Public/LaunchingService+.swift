//
//  File.swift
//  
//
//  Created by SwiftMan on 2023/02/11.
//

import Foundation
import Dependencies
import LaunchingService

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private enum LaunchingServiceKey: DependencyKey {
  public static let liveValue: any LaunchingInteractable = LaunchingService()
  public static let testValue: any LaunchingInteractable = UnimplementedLaunchingService()
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private final class UnimplementedLaunchingService: LaunchingInteractable {
  func fetchAppUpdateStatus() async throws -> AppUpdateStatus {
    let fetch: @Sendable () async throws -> AppUpdateStatus =
      unimplemented(#"@Dependency(\.launchingService).fetchAppUpdateStatus"#)
    return try await fetch()
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DependencyValues {
  var launchingService: any LaunchingInteractable {
    get { self[LaunchingServiceKey.self] }
    set { self[LaunchingServiceKey.self] = newValue }
  }
}
