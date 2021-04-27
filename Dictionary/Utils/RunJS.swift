//
//  RunJS.swift
//  Dictionary
//
//  Created by Jed Fox on 4/27/21.
//

import WebKit

extension WKWebView {
  func runJS(_ js: String) {
    if self.isLoading {
      self.evaluateJavaScript("(window.queue || (window.queue = [])).push(() => { \(js) })")
    } else {
      self.evaluateJavaScript(js)
    }
  }
}
