//
//  ViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import ZIPFoundation
import WebKit

class DictionaryProvider {
  static let shared = DictionaryProvider()

  private var archives: [String: ZIPFoundation.Archive] = [:]

  subscript(_ word: String, callback: @escaping (Data) -> ()) -> () {
    get {
      DispatchQueue.global(qos: .userInitiated).async { [self] in
        let key = String(word.first!)
        if archives[key] == nil {
          archives[key] = ZIPFoundation.Archive(
            url: Bundle.main.url(forResource: key, withExtension: "zip")!,
            accessMode: .read
          )!
        }
        var data = """
        <meta name="viewport" content="width=device-width" />
        <link rel="stylesheet" href="styles.css" />
        <style>body { margin: 20px; } </style>
      """.data(using: .utf8)!
        if let archive = archives[key],
           let entry = archive["\(word).html"] {
          _ = try! archive.extract(entry) { chunk in
            data += chunk
          }
          DispatchQueue.main.async {
            callback(data)
          }
        }
      }
    }
  }
}

class ViewController: UIViewController, UIScrollViewDelegate {

  var word: String? {
    didSet {
      self.navigationItem.title = word
      if self.webView != nil {
        loadPage()
      }
    }
  }

  @IBOutlet weak var webView: WKWebView!

  override func viewDidLoad() {
    super.viewDidLoad()
    loadPage()
    self.webView.scrollView.delegate = self
  }

  func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
//    print(self.webView.safeAreaInsets)
    if self.webView.safeAreaInsets.top > 92 {
      self.webView.scrollView.contentInset.top = -92
      self.webView.evaluateJavaScript("document.body.style.marginTop = '\(92/2 + (self.webView.safeAreaInsets.top - 92) / 2)px'")
    } else {
      self.webView.scrollView.contentInset.top = 0
    }
  }

  @IBAction func doThing(_ sender: Any) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
      print(webView.scrollView.delegate)
//      <#code#>
    }
  }
  
  func loadPage() {
    if let word = word {
      DictionaryProvider.shared[word] {
        self.webView.load($0, mimeType: "text/html", characterEncodingName: "utf-8", baseURL: Bundle.main.resourceURL!)
      }
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let nc = navigationController,
       nc.viewControllers.contains(self) {
      self.word = nil
    }
  }
}

