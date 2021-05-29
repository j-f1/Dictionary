//
//  WordsTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import Combine
import Defaults

let numberFormatter = { () -> NumberFormatter in
  let fmt = NumberFormatter()
  fmt.numberStyle = .decimal
  return fmt
}()

extension Array where Element == WordLetter {
  var totalCount: String {
    let totalCount = reduce(0) { $0 + $1.words.count }
    if totalCount == 1 {
      return "1 word"
    } else {
      return "\(numberFormatter.string(from: totalCount as NSNumber)!) words"
    }
  }
}

class WordsTableViewController: WordListController, UITableViewDelegate {
  lazy var detailVC = {
    self.splitViewController?.viewController(for: .secondary) ?? self.storyboard?.instantiateViewController(identifier: VCIdentifier.detail)
  }()

  lazy var settingsVC = SettingsViewController()

  let history = BackForwardStack<String>()
  var subscriptions: Set<AnyCancellable> = Set()

  var allWords: [WordLetter]?
  var currentSource: Source?

  var countLabel = UILabel()

  @IBOutlet weak var pinView: UIVisualEffectView!
  @IBOutlet weak var pinLabel: UILabel!
  @IBOutlet weak var pinTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var pinLeadingConstraint: NSLayoutConstraint!


  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    unpin()

    tableView.delegate = self

    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.titleView = searchController.searchBar

    pasteButton.transform = .init(translationX: 0, y: 26)

    countLabel.textColor = .secondaryLabel
    countLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    countLabel.adjustsFontForContentSizeCategory = true
    countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    countLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    countLabel.translatesAutoresizingMaskIntoConstraints = false

    self.toolbarItems = [
      UIBarButtonItem(
        title: "Settings",
        image: UIImage(systemName: "gearshape")!,
        primaryAction: UIAction { _ in
          self.present(self.settingsVC, animated: true, completion: nil)
        }
      ),
      .flexibleSpace(),
      UIBarButtonItem(customView: countLabel),
      .flexibleSpace(),
      UIBarButtonItem(
        title: "Random Word",
        image: UIImage(systemName: "shuffle")!,
        primaryAction: UIAction { _ in
          self.goToRandomWord(self)
        }
      )
    ]

    if let detailVC = detailVC as? UINavigationController,
       let customVC = detailVC.topViewController as? DetailViewController {
      customVC.loadViewIfNeeded()
      customVC.wordListVC = self
    }

    NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
      .merge(with: NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
      .throttle(
        for: .milliseconds(500),
        scheduler: RunLoop.main,
        latest: true
      )
      .map { _ in }
      .merge(with: Defaults.publisher(keys: .watchPasteboard, options: []))
      .sink { _ in self.updatePasteButton() }
      .store(in: &subscriptions)

    NotificationCenter.default.publisher(for: BackForwardStackUpdated, object: history)
      .sink { notif in
        if let detailVC = self.detailVC as? UINavigationController,
           let customVC = detailVC.topViewController as? DetailViewController,
           let word = self.history.state {
          customVC.word = word
          if let words = self.words,
             let indexPath = find(exact: word, in: words),
             self.tableView.indexPathForSelectedRow != indexPath {
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            self.tableView.scrollToRow(at: indexPath, at: .none, animated: false)
          }

          if self.navigationController?.topViewController != self {
            self.navigationController?.popToViewController(self, animated: false)
            UIView.performWithoutAnimation {
              self.showDetailViewController(detailVC, sender: self)
            }
          } else {
            self.showDetailViewController(detailVC, sender: self)
          }
        }
      }
      .store(in: &subscriptions)
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if words == nil {
      words = DictionaryProvider.loadWords(from: "boot")
      tableView.reloadData()
      DispatchQueue.global(qos: .userInitiated).async {
        let allWords = DictionaryProvider.loadWords(from: "words-by-letter")
        DispatchQueue.main.async {
          self.countLabel.text = allWords.totalCount
          self.allWords = allWords
          self.words = allWords
          self.tableView.reloadData()
          self.updatePasteButton()
        }
      }
    }
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    pinLeadingConstraint.constant = -self.view.safeAreaInsets.left
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if pinTopConstraint.constant == 0 {
      tableView.contentInset.top = pinView.frame.height
    } else {
      tableView.contentInset.top = 0
    }
  }

  // MARK: - Paste Button

  @IBOutlet weak var pasteButton: PasteButtonView!
  @IBOutlet weak var pasteLabel: UILabel!
  @IBOutlet weak var pasteButtonOffset: NSLayoutConstraint!

  var pasteTarget: IndexPath? {
    didSet {
      UIView.animate(withDuration: 0.3) {
        if self.pasteTarget != nil {
          self.pasteButton.transform = .identity
          self.pasteButton.alpha = 1
        } else {
          self.pasteButton.transform = .init(translationX: 0, y: 26)
          self.pasteButton.alpha = 0
        }
      }
    }
  }

  func updatePasteButton() {
    guard
      Defaults[.watchPasteboard],
      UIPasteboard.general.hasStrings
    else {
      pasteTarget = nil
      return
    }
    UIPasteboard.general.detectPatterns(for: [.number, .probableWebSearch, .probableWebURL]) { [self] result in
      DispatchQueue.main.async {
        if case .success(let detected) = result,
           !detected.contains(.number),
           !detected.contains(.probableWebURL) {
          if let copiedString = UIPasteboard.general.string,
             let words = words,
             let (word, indexPath) = find(query: copiedString, in: words) {
            if pasteTarget == nil || word != pasteLabel.text {
              pasteLabel.text = word
              pasteTarget = indexPath
            }
          } else {
            pasteTarget = nil
          }
        } else {
          pasteTarget = nil
        }
      }
    }
  }

  @IBAction func pasteButtonTapped() {
    if let pasteTarget = pasteTarget {
      tableView.selectRow(at: pasteTarget, animated: false, scrollPosition: .middle)
      history.move(to: pasteLabel.text!)
      self.pasteTarget = nil
    }
  }

  // MARK: - Table view delegate
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    history.move(to: words![indexPath.section].words[indexPath.row])
  }

  // MARK: - Navigation Actions
  func goToRandomWord(_ sender: Any) {
    guard let words = words else { return }
    let lengths = words.map(\.words.count)
    let totalLength = lengths.reduce(0, +)
    var row = Int.random(in: 0..<totalLength)
    var section = 0
    while row >= lengths[section] {
      row -= lengths[section]
      section += 1
    }
    let indexPath: IndexPath = IndexPath(row: row, section: section)
    tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    history.move(to: words[section].words[row])
  }

  // MARK: Pinning
  func pin(_ source: Source) {
    self.words = source.words
    self.countLabel.text = source.words.totalCount
    self.currentSource = source
    if let name = source.meta?.name {
      self.pinLabel.text = "Showing words quoting \(name)"
    }
    self.pinTopConstraint.constant = 0
    self.pinView.alpha = 1
    self.view.layoutIfNeeded()
    splitViewController?.show(.primary)
  }

  @IBAction func unpin() {
    self.words = allWords
    self.countLabel.text = allWords?.totalCount
    self.currentSource = nil
    self.pinTopConstraint.constant = -self.pinView.frame.height
    UIView.animate(withDuration: 0.2) {
      self.view.layoutIfNeeded()
      self.tableView.contentInset.top = 0
    } completion: { _ in
      UIView.animate(withDuration: 0.2) {
        self.pinView.alpha = 0
      }
    }
  }

  // MARK: Next/Previous
  var canGoToNext: Bool {
    if let word = self.history.state,
       let words = words,
       let path = find(exact: word, in: words) {
      return path != IndexPath(row: words.last!.words.count - 1, section: words.count - 1)
    }
    return false
  }
  func goToNext() {
    assert(canGoToNext)
    guard
      let words = words,
      let currentPath = find(exact: self.history.state!, in: words)
    else { return }
    if currentPath.row == words[currentPath.section].words.count - 1 {
      self.history.move(to: words[currentPath.section + 1].words.first!)
    } else {
      self.history.move(to: words[currentPath.section].words[currentPath.row + 1])
    }
  }

  var canGoToPrevious: Bool {
    if let word = self.history.state,
       let words = words,
       let path = find(exact: word, in: words) {
      return path != IndexPath(row: 0, section: 0)
    }
    return false
  }
  func goToPrevious() {
    assert(canGoToPrevious)
    guard
      let words = words,
      let currentPath = find(exact: self.history.state!, in: words)
    else { return }
    if currentPath.row == 0 {
      self.history.move(to: words[currentPath.section - 1].words.last!)
    } else {
      self.history.move(to: words[currentPath.section].words[currentPath.row - 1])
    }
  }
}
