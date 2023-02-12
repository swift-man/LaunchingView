//
//  LaunchingAlertDefaultText.swift
//  
//
//  Created by SwiftMan on 2023/02/12.
//

import Dependencies
import Foundation

public struct LaunchingAlertDefaultText {
  
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

extension LaunchingAlertDefaultText: TestDependencyKey {
  public static var testValue: LaunchingAlertDefaultText {
    LaunchingAlertDefaultText()
  }
}

extension DependencyValues {
  public var launchingAlertDefaultText: LaunchingAlertDefaultText {
    get { self[LaunchingAlertDefaultText.self] }
    set { self[LaunchingAlertDefaultText.self] = newValue }
  }
}
