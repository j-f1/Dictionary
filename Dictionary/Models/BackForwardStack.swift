//
//  BackForwardStack.swift
//  Dictionary
//
//  Created by Jed Fox on 4/16/21.
//

import Foundation
import Combine

let BackForwardStackUpdated = Notification.Name("BackForwardStack.updated")

class BackForwardStack<State: Equatable> {
  private var history: [State]
  private var cursor: Int

  var state: State? { cursor >= 0 ? history[cursor] : nil }

  init() {
    history = []
    cursor = -1
  }
  init(initialState: State) {
    history = [initialState]
    cursor = 0
  }

  var canGoBack: Bool { cursor < history.count - 1 }
  var canGoForward: Bool { cursor > 0 }

  func goBack() {
    assert(canGoBack)
    cursor += 1
    NotificationCenter.default.post(
      name: BackForwardStackUpdated,
      object: self,
      userInfo: ["isBackForward": true]
    )
  }
  func goForward() {
    assert(canGoForward)
    cursor -= 1
    NotificationCenter.default.post(
      name: BackForwardStackUpdated,
      object: self,
      userInfo: ["isBackForward": true]
    )
  }

  func move(to state: State) {
    // don’t duplicate states
    if state == self.state { return }

    if history.isEmpty {
      history = [state]
    } else {
      history = [state] + history.dropFirst(cursor)
    }
    cursor = 0
    NotificationCenter.default.post(name: BackForwardStackUpdated, object: self)
  }
}
