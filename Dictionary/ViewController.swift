//
//  ViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import ZIPFoundation
import WebKit

class ViewController: UIViewController {

  static var archive = ZIPFoundation.Archive(url: Bundle.main.url(forResource: "dict", withExtension: "zip")!, accessMode: .read)!

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
  }

  func loadPage() {
    var data = """
      <meta name="viewport" content="width=device-width" />
      <link rel="stylesheet" href="styles.css" />
      <style>body { margin: 20px; } </style>
    """.data(using: .utf8)!
    if let word = word,
       let entry = Self.archive["defs/\(word).html"] {
      _ = try! Self.archive.extract(entry) { chunk in
        data += chunk
      }
      self.webView.load(data, mimeType: "text/html", characterEncodingName: "utf-8", baseURL: Bundle.main.resourceURL!)
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

