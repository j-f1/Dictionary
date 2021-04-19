//
//  DictionaryInfoView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/18/21.
//

import SwiftUI
import WebKit
import BetterSafariView

extension UIColor {
  var cssValue: String {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    UIColor.systemBlue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return "rgba(\(red * 100)%, \(green * 100)%, \(blue * 100)%, \(alpha * 100))"
  }
}

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

    init(externalURL: Binding<URL?>, height: Binding<CGFloat>) {
      _externalURL = externalURL
      _height = height
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

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if let height = message.body as? CGFloat {
        DispatchQueue.main.async {
          self.height = height
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(externalURL: $externalURL, height: $height)
  }

  func makeUIView(context: Context) -> WKWebView {
    let wv = WKWebView()
    wv.scrollView.isScrollEnabled = false
    wv.navigationDelegate = context.coordinator
    wv.isOpaque = false
    wv.backgroundColor = .clear
    wv.scrollView.backgroundColor = .clear
    wv.configuration.userContentController.add(context.coordinator, name: "height")
    return wv
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString("""
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
      <style>
        :root {
          color-scheme: light dark;
          font: -apple-system-body;
          -webkit-text-size-adjust: 100%;
          -webkit-user-select: none;
        }
        body {
          margin: 0;
          display: flex;
          justify-content: center;
          flex-direction: column;
          height: 100%;
        }
        p:first-child { margin-top: 0.5em; }
        p:last-child { margin-bottom: 0.5em; }
        code { font-family: ui-monospace; }
        a { color: rgba(\(UIColor(named: "AccentColor")!.cgColor.components!.map { "\($0 * 100)%" }.joined(separator: ", "))) }
      </style>
      <script>
        const updateHeight = () => {
          debugger
          window.webkit.messageHandlers.height.postMessage(document.getElementById("root").clientHeight)
        }
        setInterval(updateHeight, 500)
        window.onload = updateHeight
        window.onresize = updateHeight
      </script>
      <div id="root">\(htmlContent)</div>
    """, baseURL: nil)
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

struct DictionaryInfoView: View {
  var body: some View {
    Form {
      Section(header: Text("")) {
        HTMLView(style: "text-align: center; font: \(UIFont.systemFontSize * 1.2)px ui-serif", """
          Webster's Revised Unabridged Dictionary<br>
          Version published 1913<br>
          by the C. & G. Merriam Co.<br>
          Springfield, Mass.<br>
          Under the direction of<br>
          Noah Porter, D.D., LL.D.
        """)
      }
      Section {
        HTMLView("The content of this app comes from the 1913 edition of <a href='https://en.wikipedia.org/wiki/Webster%27s_Dictionary#1913_edition'>Webster’s Dictionary</a>.")
        HTMLView("The dictionary was digitized as part of the <a href='https://gcide.gnu.org.ua'>GCIDE</a> project maintained by Patrick J. Cassidy and Sergey Poznyakoff.")
        HTMLView("""
          The GCIDE data was further processed into HTML using <a href="https://github.com/ponychicken/WebsterParser"><code>WebsterParser</code></a>, written by <a href="https://github.com/ponychicken">ponychicken</a>, <a href="https://thejeffbyrnes.com">Jeff Byrnes</a>, myself, and all the other <a href="https://github.com/ponychicken/WebsterParser/graphs/contributors">contributors</a>.
        """)
        HTMLView("""
          This app is free software, and you can grab its source code <a href="https://github.com/j-f1/Dictionary">on GitHub</a>!
        """)
      }
    }
    .navigationTitle("About Webster’s Dictionary")
  }
}

struct DictionaryInfoView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      DictionaryInfoView()
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}
