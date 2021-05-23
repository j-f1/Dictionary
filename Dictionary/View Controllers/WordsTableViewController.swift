//
//  WordsTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import Combine
import Defaults

fileprivate enum CellIdentifier {
  static let word = "WordRow"
}

class WordsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISplitViewControllerDelegate {

  let searchController: UISearchController = {
    let sc = UISearchController(searchResultsController: nil)
    sc.hidesNavigationBarDuringPresentation = false
    sc.automaticallyShowsCancelButton = false
    sc.obscuresBackgroundDuringPresentation = false
    sc.searchBar.searchBarStyle = .prominent
    sc.searchBar.autocorrectionType = .default
    sc.searchBar.autocapitalizationType = .none
    sc.searchBar.returnKeyType = .done
    sc.searchBar.enablesReturnKeyAutomatically = false
    return sc
  }()

  lazy var detailVC = {
    self.splitViewController?.viewController(for: .secondary) ?? self.storyboard?.instantiateViewController(identifier: VCIdentifier.detail)
  }()

  lazy var settingsVC = SettingsViewController()

  @IBOutlet weak var tableView: UITableView!

  let history = BackForwardStack<IndexPath>()
  var subscriptions: Set<AnyCancellable> = Set()

  var allWords: [WordLetter]?

  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    searchController.searchResultsUpdater = self
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.titleView = searchController.searchBar

    pasteButton.transform = .init(translationX: 0, y: 26)

    tableView.dataSource = self
    tableView.delegate = self

    self.toolbarItems = [
      UIBarButtonItem(
        title: "Settings",
        image: UIImage(systemName: "gearshape")!,
        primaryAction: UIAction { _ in
          self.present(self.settingsVC, animated: true, completion: nil)
        }
      ),
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
           let indexPath = self.history.state {
          customVC.word = self.allWords![indexPath.section].words[indexPath.row]
          if self.tableView.indexPathForSelectedRow != indexPath {
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
    self.splitViewController?.delegate = self
    if self.allWords == nil {
      self.allWords = DictionaryProvider.loadWords(from: "boot")
      tableView.reloadData()
      DispatchQueue.global(qos: .userInitiated).async {
        let allWords = DictionaryProvider.loadWords(from: "words-by-letter")
        DispatchQueue.main.async {
          self.allWords = allWords
          self.tableView.reloadData()
          self.updatePasteButton()
        }
      }
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
             let (word, indexPath) = find(query: copiedString, in: allWords!) {
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
      history.move(to: pasteTarget)
      self.pasteTarget = nil
    }
  }

  // MARK: - UISearchResultsUpdating
  func updateSearchResults(for searchController: UISearchController) {
    guard let query = searchController.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return }
    guard let section = allWords!.firstIndex(where: { query.first == $0.letter.first }) else { return }
    if let row = allWords![section].words.firstIndex(where: { $0 > query }) {
      tableView.scrollToRow(at: IndexPath(row: row == 0 ? row : row - 1, section: section), at: .top, animated: false)
    }
  }

  // MARK: - Table view data source

  func numberOfSections(in tableView: UITableView) -> Int {
    allWords?.count ?? 0
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    allWords![section].words.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.word, for: indexPath)
    cell.textLabel?.text = allWords![indexPath.section].words[indexPath.row]
    return cell
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    nil
  }

  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    allWords?.map { $0.letter.uppercased() }
  }

  // MARK: - Table view delegate
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    history.move(to: indexPath)
  }

  // MARK: - Navigation Actions
  func goToRandomWord(_ sender: Any) {
    let lengths = allWords!.map(\.words.count)
    let totalLength = lengths.reduce(0, +)
    var row = Int.random(in: 0..<totalLength)
    var section = 0
    while row >= lengths[section] {
      row -= lengths[section]
      section += 1
    }
    let indexPath: IndexPath = IndexPath(row: row, section: section)
    tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    history.move(to: indexPath)
  }

  // MARK: Next/Previous
  var canGoToNext: Bool {
    self.history.state != nil &&
      self.history.state
      != IndexPath(row: allWords!.last!.words.count - 1, section: allWords!.count - 1)
  }
  func goToNext() {
    assert(canGoToNext)
    let currentPath = self.history.state!
    if currentPath.row == allWords![currentPath.section].words.count - 1 {
      self.history.move(to: IndexPath(row: 0, section: currentPath.section + 1))
    } else {
      self.history.move(to: IndexPath(row: currentPath.row + 1, section: currentPath.section))
    }
  }

  var canGoToPrevious: Bool {
    self.history.state != nil && self.history.state != IndexPath(row: 0, section: 0)
  }
  func goToPrevious() {
    assert(canGoToPrevious)
    let currentPath = self.history.state!
    if currentPath.row == 0 {
      self.history.move(to: IndexPath(row: allWords![currentPath.section - 1].words.count - 1, section: currentPath.section - 1))
    } else {
      self.history.move(to: IndexPath(row: currentPath.row - 1, section: currentPath.section))
    }
  }
}
