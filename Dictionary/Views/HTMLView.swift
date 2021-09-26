//
//  HTMLView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/27/21.
//

import SwiftUI
import WebKit
import BetterSafariView

struct HTMLStringView: UIViewRepresentable {
  let htmlContent: String
  @Binding var externalURL: URL?
  @Binding var height: CGFloat
  @Environment(\.colorScheme) var colorScheme // to trigger updates

  init(externalURL: Binding<URL?>, height: Binding<CGFloat>, _ htmlContent: String) {
    self._externalURL = externalURL
    self._height = height
    self.htmlContent = htmlContent
  }

  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Binding var externalURL: URL?
    @Binding var height: CGFloat
    var htmlContent: String?

    init(externalURL: Binding<URL?>, height: Binding<CGFloat>, htmlContent: String) {
      _externalURL = externalURL
      _height = height
      self.htmlContent = htmlContent
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if let url = navigationAction.request.url,
         ["http", "https"].contains(url.scheme) {
        self.externalURL = url
        decisionHandler(.cancel)
      } else {
        decisionHandler(.allow)
      }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      if let htmlContent = htmlContent {
        inject(htmlContent: htmlContent, into: webView)
        self.htmlContent = nil
      }
    }

    func inject(htmlContent: String, into webView: WKWebView) {
      let accentColor = "rgba(\(UIColor(named: "AccentColor")!.cgColor.components!.map { "\($0 * 100)%" }.joined(separator: ", ")))"
      webView.runJS("""
    debugger;
      document.body.style.setProperty('--accent-color', '\(accentColor)');
    document.getElementById("root").innerHTML = \(String(data: try! JSONEncoder().encode(htmlContent), encoding: .utf8)!)
    """)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if let height = message.body as? CGFloat {
        DispatchQueue.main.async {
          self.height = height
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(externalURL: $externalURL, height: $height, htmlContent: htmlContent)
  }

  func makeUIView(context: Context) -> WKWebView {
    let wv = WKWebView()
    wv.scrollView.isScrollEnabled = false
    wv.navigationDelegate = context.coordinator
    wv.isOpaque = false
    wv.backgroundColor = .clear
    wv.scrollView.backgroundColor = .clear
    wv.configuration.userContentController.add(context.coordinator, name: "height")
    wv.loadFileURL(Bundle.main.url(forResource: "html-view", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    return wv
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    if context.coordinator.htmlContent != nil {
      context.coordinator.htmlContent = htmlContent
    }
    context.coordinator.inject(htmlContent: htmlContent, into: webView)
  }
}

struct HTMLView: View {
  @State private var externalURL: URL?
  @State private var height: CGFloat = 0
  let htmlContent: String
  let style: String
  init(style: String = "", _ htmlContent: String) {
    self.htmlContent = htmlContent
    self.style = style
  }
  var body: some View {
    HTMLStringView(externalURL: $externalURL, height: $height, "<p style='\(style)'>\(htmlContent)</p>")
      .frame(height: height)
      .sheet(item: $externalURL) { url in
        SafariView(url: url)
      }
  }
}

struct HTMLView_Previews: PreviewProvider {
  static var previews: some View {
    Form {
      HTMLView("hello!")
    }
  }
}
