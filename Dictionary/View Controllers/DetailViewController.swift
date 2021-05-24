//
//  DetailViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import WebKit
import Combine

fileprivate enum SegueIdentifier {
  static let showSourceSheet = "showSourceSheet"
}

class NotActuallyAPromise<Result> {
  private(set) var result: Result? = nil
  private var listeners: [(Result) -> ()] = []
  func fetchResult(_ cb: @escaping (Result) -> ()) {
    if let result = result {
      cb(result)
    } else {
      listeners.append(cb)
    }
  }
  init(_ cb: (@escaping (Result) -> ()) -> ()) {
    cb { result in
      self.result = result
      self.listeners.forEach { $0(result) }
    }
  }
}

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


  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    UIMenuController.shared.menuItems = [.init(title: "Define", action: #selector(define(_:)))]

    webView.scrollView.delegate = self
    webView.loadFileURL(Bundle.main.url(forResource: "detail", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    webView.configuration.userContentController.add(self, name: "showSource")

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
    if let result = find(query: word, in: self.wordListVC.allWords!) {
      self.wordListVC.history.move(to: result.indexPath)
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
    } else if let sourceName = message.body as? String {
      self.performSegue(
        withIdentifier: SegueIdentifier.showSourceSheet,
        sender: NotActuallyAPromise { DictionaryProvider.shared[source: sourceName, $0] }
      )
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == SegueIdentifier.showSourceSheet,
       let nav = segue.destination as? UINavigationController,
       let vc = nav.viewControllers.first as? SourceTableViewController,
       let sender = sender as? NotActuallyAPromise<Source?>? {
      sender?.fetchResult {
        vc.source = $0
      }
    }
  }
}
