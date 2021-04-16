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



class ViewController: UIViewController, UIScrollViewDelegate {

  var word: String? {
    didSet {
//      self.navigationItem.tile = word
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

  override func viewDidLoad() {
    super.viewDidLoad()

    webView.scrollView.delegate = self
    webView.loadHTMLString("""
      <meta name="viewport" content="width=device-width" />
      <link rel="stylesheet" href="styles.css" />
      <style>
        body { margin: 20px; -webkit-text-size-adjust: 100%; }
        :root { color-scheme: light dark; }
        hr {
          margin-top: 2em;
          margin-bottom: -2em;
          border: 1px solid currentcolor;
          opacity: 0.5;
        }
      </style>
    """, baseURL: Bundle.main.resourceURL!)

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


    self.navigationItem.titleView = self.labelContainer
    loadPage()
    self.scrollViewDidScroll(webView.scrollView)
  }

  func kickTitle() {
    self.navigationItem.titleView = nil
    self.labelContainer.removeFromSuperview()
    self.navigationItem.titleView = self.labelContainer
    labelContainer.sizeToFit()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    kickTitle()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    kickTitle()
    let scrollTop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
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

//    let fraction = max(0, min((scrollTop - 20) / 20, 1))
//
//    titleLabel.alpha = fraction
//    topConstraint.constant = -(1 - fraction) * 20
//    bottomConstraint.constant = -(1 - fraction) * 20
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
        let escapedBody = String(data: try! JSONEncoder().encode(String(data: $0, encoding: .utf8)), encoding: .utf8)!
        if self.webView.isLoading {
          self.webView.evaluateJavaScript("window.onload = () => document.body.innerHTML = \(escapedBody)")

        } else {
          self.webView.evaluateJavaScript("document.body.innerHTML = \(escapedBody)")
        }
      }
    }
  }
}
