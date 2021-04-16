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
        var data = Data()
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


extension UINavigationController {
  func hideHairline() {
    if let hairline = findHairlineImageViewUnder(navigationBar) {
      hairline.isHidden = true
    }
  }
  func restoreHairline() {
    if let hairline = findHairlineImageViewUnder(navigationBar) {
      hairline.isHidden = false
    }
  }
  func findHairlineImageViewUnder(_ view: UIView) -> UIImageView? {
    if view is UIImageView && view.bounds.size.height <= 1.0 {
      return view as? UIImageView
    }
    for subview in view.subviews {
      if let imageView = self.findHairlineImageViewUnder(subview) {
        return imageView
      }
    }
    return nil
  }
}



class ViewController: UIViewController, UIScrollViewDelegate, WKScriptMessageHandler {


  var word: String? {
    didSet {
      self.navigationItem.title = word
      self.titleLabel.alpha = 0
      self.titleLabel.text = word
      self.titleLabel.sizeToFit()
      if self.webView != nil {
        loadPage()
      }
    }
  }

  @IBOutlet weak var webView: WKWebView!

  let labelContainer = UIView()
  let titleLabel = UILabel()
  var titleShown = false

  var wordListVC: WordsTableViewController!

  @objc func define(_ sender: Any) {
    webView.evaluateJavaScript("window.getSelection().toString()") { selection, _ in
      if let selection = selection as? String,
         let result = self.wordListVC.lookUpWord(selection) {
        self.wordListVC.openDetail(forRowAt: result.indexPath)
      }
    }
  }

  @IBAction func randomWord(_ sender: Any) {
    self.wordListVC.goToRandomWord(sender)
  }

  func runJS(_ js: String) {
//    print(js)
    if self.webView.isLoading {
      self.webView.evaluateJavaScript("(window.queue || (window.queue = [])).push(() => { \(js) })") { res, err in
        if let err = err {
          print(err)
        }
      }
    } else {
      self.webView.evaluateJavaScript("{\(js)}") { res, err in
        if let err = err {
          print(err)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    UIMenuController.shared.menuItems = [.init(title: "Define", action: #selector(define(_:)))]

    webView.scrollView.delegate = self
    webView.loadHTMLString("""
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
      <link rel="stylesheet" href="styles.css" />
      <style>
        body {
          margin: 20px;
          -webkit-text-size-adjust: 100%;
          overflow-x: hidden;
        }
        :root {
          color-scheme: light dark;
          overflow-x: hidden;
          max-width: calc(80ch + 20px);
          margin: auto;
        }
        hr {
          margin-top: 2em;
          margin-bottom: -2em;
          border: 1px solid currentcolor;
          opacity: 0.5;
        }
        body:empty {
          overflow: hidden;
        }
        body:empty::after {
          content: "Select a word";
          font-family: system-ui;
          opacity: 0.66;
          font-size: 2.1em;
          position: absolute;
          top: 50%;
          left: 0;
          transform: translateY(-50%);
          width: 100%;
          text-align: center;
        }
      </style>
      <script>
        window.onload = () => {
          if (window.queue) window.queue.forEach(f => f())
          window.queue = null
        }
      </script>
    """, baseURL: Bundle.main.resourceURL!)

    webView.configuration.userContentController.add(self, name: "vc")

    labelContainer.addSubview(titleLabel)
    titleLabel.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)

    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    labelContainer.addConstraint(
      NSLayoutConstraint(
        item: labelContainer, attribute: .leading,
        relatedBy: .equal,
        toItem: titleLabel, attribute: .leading,
        multiplier: 1, constant: 0
      )
    )
    labelContainer.addConstraint(
      NSLayoutConstraint(
        item: labelContainer, attribute: .trailing,
        relatedBy: .equal,
        toItem: titleLabel, attribute: .trailing,
        multiplier: 1, constant: 0
      )
    )
    labelContainer.addConstraint(
      NSLayoutConstraint(
        item: labelContainer, attribute: .top,
        relatedBy: .equal,
        toItem: titleLabel, attribute: .top,
        multiplier: 1, constant: 0
      )
    )
    labelContainer.addConstraint(
      NSLayoutConstraint(
        item: labelContainer, attribute: .bottom,
        relatedBy: .equal,
        toItem: titleLabel, attribute: .bottom,
        multiplier: 1, constant: 0
      )
    )


    navigationItem.titleView = self.labelContainer
    loadPage()
    self.scrollViewDidScroll(webView.scrollView)

    NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    preferredContentSizeChanged(nil)
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    switch message.body as? String {
    case "update":
      self.update()
      break
    default: break
    }
  }


  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.traitCollectionDidChange(nil)
  }

  @objc private func preferredContentSizeChanged(_ notification: Notification?) {
    let font = UIFont.preferredFont(forTextStyle: .body)
//    print("Point Size", font.pointSize)
    runJS("document.body.style.fontSize = '\(font.pointSize)px'")
  }

  func kickTitle() {
    self.navigationItem.titleView = nil
    self.labelContainer.removeFromSuperview()
    self.navigationItem.titleView = self.labelContainer
    labelContainer.sizeToFit()
  }

  func update() {
    kickTitle()
    navigationController?.isToolbarHidden = traitCollection.horizontalSizeClass == .regular
    if traitCollection.horizontalSizeClass == .regular && traitCollection.userInterfaceIdiom == .pad {
      runJS("document.body.style.marginTop = '0'")
    } else {
      runJS("document.body.style.marginTop = null")
    }
    if webView.scrollView.contentSize.height <= webView.scrollView.bounds.height {
      runJS("""
        const padding = (window.innerWidth - document.body.scrollWidth) / 2 - \(webView.scrollView.adjustedContentInset.top)
        if (padding > 0)
          document.body.style.paddingTop = `${padding}px`
        else
          document.body.style.paddingTop = null
      """)
    } else {
      runJS("document.body.style.paddingTop = null")
    }
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil, completion: { _ in
      self.update()
    })
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    update()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.x != 0 {
      scrollView.contentOffset.x = 0
    }

    let scrollTop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top

    if scrollTop != 0,
       scrollView.contentSize.height <= scrollView.bounds.height {
      scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
      self.titleLabel.alpha = 0
      titleShown = false
      return
    }

    if traitCollection.horizontalSizeClass == .regular && traitCollection.userInterfaceIdiom == .pad {
      self.titleLabel.alpha = max(0, min(1, scrollTop / 16))
    } else {
      if scrollTop > 40 && !titleShown {
        titleShown = true
        UIView.animate(withDuration: 0.4) {
          self.titleLabel.alpha = 1
        }
      } else if scrollTop < 40 && titleShown {
        titleShown = false
        UIView.animate(withDuration: 0.4) {
          self.titleLabel.alpha = 0
        }
      }
    }
  }

  func loadPage() {
    if let word = word {
      DictionaryProvider.shared[word] {
        let escapedBody = String(data: try! JSONEncoder().encode(String(data: $0, encoding: .utf8)), encoding: .utf8)!
        self.runJS("""
          document.body.innerHTML = \(escapedBody);
          setTimeout(() => webkit.messageHandlers.vc.postMessage("update"), 20);
        """)
      }
    }
  }
}
