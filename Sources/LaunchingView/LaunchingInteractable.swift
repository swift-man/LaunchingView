//
//  LaunchingInteractable.swift
//  
//
//  Created by SwiftMan on 2023/01/31.
//

import LaunchingService

/// LaunchingView 를 구동하기 위해서 LaunchingService의 구성이 필요합니다.
///
/// 앱에서 아래와 같은 style 로 환경 세팅이 필요합니다.
///
///     import Dependencies
///     import LaunchingService
///     import LaunchingView
///
///     extension LaunchingService: DependencyKey, LaunchingInteractable {
///        public static var liveValue = LaunchingService(keyStore: LaunchingServiceKeyStore(...))
///     }
///
///     extension DependencyValues {
///       var launchingService: LaunchingService {
///         get { self[LaunchingService.self] }
///         set { self[LaunchingService.self] = newValue }
///       }
///    }
public protocol LaunchingInteractable: AnyObject {
  func fetchLaunchingConfig() async throws -> AppUpdateStatus
}
