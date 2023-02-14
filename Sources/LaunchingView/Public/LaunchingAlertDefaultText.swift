//
//  LaunchingAlertDefaultText.swift
//  
//
//  Created by SwiftMan on 2023/02/12.
//

import Dependencies
import Foundation

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct LaunchingAlertDefaultText {
  
  @available(iOS 15.0, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public struct ForceUpdate {
    let title: String
    let message: String
    let done: String
    
    public init(title: String = Bundle.main.displayName,
                message: String = "",
                done: String = "update") {
      self.title = title
      self.message = message
      self.done = done
    }
  }
  
  @available(iOS 15.0, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public struct OptionalUpdate {
    let title: String
    let message: String
    let cancel: String
    let done: String
    
    public init(title: String = Bundle.main.displayName,
                message: String = "",
                cancel: String = "cancel",
                done: String = "update") {
      self.title = title
      self.message = message
      self.cancel = cancel
      self.done = done
    }
  }
  
  @available(iOS 15.0, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public struct Notice {
    let title: String
    let message: String
    let cancel: String
    let done: String
    
    public init(title: String = Bundle.main.displayName,
                message: String = "",
                cancel: String = "cancel",
                done: String = "done") {
      self.title = title
      self.message = message
      self.cancel = cancel
      self.done = done
    }
  }
  
  let forceUpdate: ForceUpdate
  let optionalUpdate: OptionalUpdate
  let notice: Notice
  
  public init(forceUpdate: ForceUpdate = ForceUpdate(),
              optionalUpdate: OptionalUpdate = OptionalUpdate(),
              notice: Notice = Notice()) {
    self.forceUpdate = forceUpdate
    self.optionalUpdate = optionalUpdate
    self.notice = notice
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LaunchingAlertDefaultText: TestDependencyKey {
  public static var testValue: LaunchingAlertDefaultText {
    LaunchingAlertDefaultText()
  }
}

@available(iOS 15.0, macOS 12, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DependencyValues {
  public var launchingAlertDefaultText: LaunchingAlertDefaultText {
    get { self[LaunchingAlertDefaultText.self] }
    set { self[LaunchingAlertDefaultText.self] = newValue }
  }
}
