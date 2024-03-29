//
//  DetailViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import WebKit
import Combine

class DetailViewController: UIViewController, UIScrollViewDelegate, WKScriptMessageHandler {

  @IBOutlet weak var webView: WKWebView!

  let labelContainer = UIView()
  let titleLabel = UILabel()
  var titleShown = false

  var backButton: UIBarButtonItem!
  var forwardButton: UIBarButtonItem!
  var navBarButtons: [UIBarButtonItem]!
  var historySubscription: AnyCancellable?

  // MARK: - Observed Properties
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

  var wordListVC: WordsTableViewController! {
    didSet {
      historySubscription = NotificationCenter.default
        .publisher(for: BackForwardStackUpdated, object: wordListVC.history)
        .merge(with: Just(Notification(name: BackForwardStackUpdated))) // immediately
        .sink { _ in
          self.backButton.isEnabled = self.wordListVC.history.canGoBack
          self.navBarButtons[0].isEnabled = self.wordListVC.history.canGoBack
          self.forwardButton.isEnabled = self.wordListVC.history.canGoForward
          self.navBarButtons[1].isEnabled = self.wordListVC.history.canGoForward
          self.navigationItem.rightBarButtonItems![1].isEnabled = self.wordListVC.canGoToPrevious
          self.navigationItem.rightBarButtonItems![0].isEnabled = self.wordListVC.canGoToNext
        }
    }
  }

  var sourceNavVC: UINavigationController!

  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    sourceNavVC = storyboard?.instantiateViewController(identifier: "sourceNavController") as! UINavigationController?

    UIMenuController.shared.menuItems = [.init(title: "Define", action: #selector(define(_:)))]

    webView.scrollView.delegate = self
    webView.loadFileURL(Bundle.main.url(forResource: "detail", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    webView.configuration.userContentController.add(self, name: "showSource")
    webView.allowsLinkPreview = false

    labelContainer.addSubview(titleLabel)
    titleLabel.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)

    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    let addEqualityConstraint = { [self] (attribute: NSLayoutConstraint.Attribute) in
      labelContainer.addConstraint(
        NSLayoutConstraint(
          item: labelContainer, attribute: attribute,
          relatedBy: .equal,
          toItem: titleLabel, attribute: attribute,
          multiplier: 1, constant: 0
        )
      )
    }
    addEqualityConstraint(.leading)
    addEqualityConstraint(.trailing)
    addEqualityConstraint(.top)
    addEqualityConstraint(.bottom)

    let makeBackButton = {
      UIBarButtonItem(
        title: "Back",
        image: UIImage(systemName: "chevron.backward")!,
        primaryAction: UIAction { _ in
          self.wordListVC.history.goBack()
        }
      )
    }

    let makeForwardButton = {
      UIBarButtonItem(
        title: "Forward",
        image: UIImage(systemName: "chevron.forward")!,
        primaryAction: UIAction { _ in
          self.wordListVC.history.goForward()
        }
      )
    }

    backButton = makeBackButton()
    forwardButton = makeForwardButton()
    navBarButtons = [makeBackButton(), makeForwardButton()]

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        title: "Next",
        image: UIImage(systemName: "chevron.down")!,
        primaryAction: UIAction { _ in
          self.wordListVC.goToNext()
        }
      ),
      UIBarButtonItem(
        title: "Previous",
        image: UIImage(systemName: "chevron.up")!,
        primaryAction: UIAction { _ in
          self.wordListVC.goToPrevious()
        }
      ),
    ]

    self.toolbarItems = [
      self.backButton,
      .fixedSpace(30),
      self.forwardButton,
      .flexibleSpace(),
      UIBarButtonItem(
        title: "Random Word",
        image: UIImage(systemName: "shuffle")!,
        primaryAction: UIAction { _ in
          self.wordListVC.goToRandomWord(self)
        }
      )
    ]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    navigationItem.titleView = self.labelContainer
    loadPage()
    self.scrollViewDidScroll(webView.scrollView)

    NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    preferredContentSizeChanged(nil)
    traitCollectionDidChange(nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.traitCollectionDidChange(nil)

    if let contentView = webView.scrollView.subviews.first(where: { $0.interactions.count > 1 }),
       let dragInteraction = (contentView.interactions.compactMap { $0 as? UIDragInteraction }.first)  {
      contentView.removeInteraction(dragInteraction)
    }
  }

  // MARK: - Events
  @objc private func preferredContentSizeChanged(_ notification: Notification?) {
    let font = UIFont.preferredFont(forTextStyle: .body)
    webView.runJS("document.body.style.fontSize = '\(font.pointSize)px'")
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    kickTitle()

    let isRegularWidth = traitCollection.horizontalSizeClass == .regular

    self.navigationController?.setToolbarHidden(isRegularWidth, animated: false)
    self.navigationItem.leftBarButtonItems = isRegularWidth ? navBarButtons : []

    if isRegularWidth && traitCollection.userInterfaceIdiom == .pad {
      webView.runJS("document.body.style.marginTop = '0'")
    } else {
      webView.runJS("document.body.style.marginTop = null")
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.x != 0 {
      scrollView.contentOffset.x = 0
    }

    let scrollTop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top

    if scrollView.contentSize.height <= scrollView.bounds.height {
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
        UIView.animate(withDuration: 0.2) {
          self.titleLabel.alpha = 1
        }
      } else if scrollTop < 40 && titleShown {
        titleShown = false
        UIView.animate(withDuration: 0.2) {
          self.titleLabel.alpha = 0
        }
      }
    }
  }

  // MARK: - Methods
  func loadPage() {
    if let word = word {
      DictionaryProvider.shared[word: word] {
        let escapedBody = String(data: try! JSONEncoder().encode(String(data: $0, encoding: .utf8)), encoding: .utf8)!
        self.webView.runJS("document.body.innerHTML = \(escapedBody)")
      }
    }
  }

  @objc func define(_ sender: Any) {
    webView.evaluateJavaScript("window.getSelection().toString()") { selection, _ in
      if let selection = selection as? String {
        self.navigateDictionary(to: selection)
      }

    }
  }

  @discardableResult
  func navigateDictionary(to word: String) -> Bool {
    if let (word, _) = searchFor(query: word, in: self.wordListVC.allWords!) {
      self.wordListVC.history.move(to: word)
      return true
    }
    return false
  }

  func kickTitle() {
    self.navigationItem.titleView = nil
    self.labelContainer.removeFromSuperview()
    self.navigationItem.titleView = self.labelContainer
    labelContainer.sizeToFit()
  }

  // MARK: - Script message handler

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if let bible = message.body as? [Any] {
      print(bible)
    } else if let body = message.body as? [String: Any],
              let rect = body["rect"] as? [String: CGFloat],
              let x = rect["x"],
              let y = rect["y"],
              let width = rect["width"],
              let height = rect["height"],
              let sourceName = body["source"] as? String {
      sourceNavVC.modalPresentationStyle = .popover
      let present = { [self] in
        sourceNavVC.popoverPresentationController?.sourceView = webView
        sourceNavVC.popoverPresentationController?.sourceRect = CGRect(x: x, y: y + webView.safeAreaInsets.top, width: width, height: height)
        if #available(iOS 15.0, *), let sheetController = sourceNavVC.popoverPresentationController?.adaptiveSheetPresentationController {
          sheetController.detents = [.medium(), .large()]
          sheetController.largestUndimmedDetentIdentifier = .medium
          sheetController.widthFollowsPreferredContentSizeWhenEdgeAttached = true
          sheetController.prefersEdgeAttachedInCompactHeight = true
          sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
          sheetController.prefersGrabberVisible = traitCollection.verticalSizeClass == .regular
        }
        DictionaryProvider.shared[source: sourceName] { source in
          if let vc = self.sourceNavVC.viewControllers.first as? SourceTableViewController {
            vc.detailVC = self
            vc.source = source
          }
        }
        self.present(sourceNavVC, animated: true, completion: nil)
      }
      if sourceNavVC.presentingViewController != nil {
        sourceNavVC.dismiss(animated: true, completion: present)
      } else {
        present()
      }
    }
  }
}
