//
//  WordsTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit
import Combine

func loadWords(from url: URL) -> [WordLetter] {
  let data = try! JSONDecoder().decode([WordLetter].self, from: Data(contentsOf: url))

  return Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ'-").map { name in
    data.first { $0.letter.uppercased() == String(name) }!
  }
}

extension String {
 func removeCharacters(from forbiddenChars: CharacterSet) -> String {
    let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
    return String(String.UnicodeScalarView(passed))
  }
}


class WordsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISplitViewControllerDelegate {

  let searchController = UISearchController(searchResultsController: nil)

  lazy var detailVC = {
    self.splitViewController?.viewController(for: .secondary) ?? self.storyboard?.instantiateViewController(identifier: "DetailVC")
  }()

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var pasteButton: PasteButtonView!
  @IBOutlet weak var pasteLabel: UILabel!
  @IBOutlet weak var pasteButtonOffset: NSLayoutConstraint!

  var pasteTarget: IndexPath? {
    didSet {
      if pasteTarget != nil {
        UIView.animate(withDuration: 0.3) {
          self.pasteButton.transform = .identity
          self.pasteButton.alpha = 1
        }
      } else {
        UIView.animate(withDuration: 0.3) {
          self.pasteButton.transform = .init(translationX: 0, y: 26)
          self.pasteButton.alpha = 0
        }
      }
    }
  }

  var allWords: [WordLetter]? { didSet {
    tableView.reloadData()
    updatePasteButton()
  } }

  var pasteboardWatcher: AnyCancellable?

  override func viewDidLoad() {
    super.viewDidLoad()

    searchController.searchResultsUpdater = self
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.automaticallyShowsCancelButton = false
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.searchBarStyle = .prominent
    searchController.searchBar.returnKeyType = .done
    searchController.searchBar.enablesReturnKeyAutomatically = false
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.titleView = searchController.searchBar
    navigationController!.isToolbarHidden = false

    pasteButton.transform = .init(translationX: 0, y: 26)

    tableView.dataSource = self
    tableView.delegate = self

    DispatchQueue.main.async {
      self.splitViewController?.delegate = self
      self.allWords = loadWords(
        from: Bundle.main.url(
          forResource: "boot",
          withExtension: "json"
        )!
      )
      DispatchQueue.global(qos: .userInitiated).async {
        let allWords = loadWords(
          from: Bundle.main.url(
            forResource: "words-by-letter",
            withExtension: "json"
          )!
        )

        DispatchQueue.main.async {
          self.allWords = allWords
        }
      }
    }

    if let detailVC = detailVC as? UINavigationController,
       let customVC = detailVC.topViewController as? ViewController {
      customVC.loadViewIfNeeded()
    }

    self.pasteboardWatcher =
      NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
      .merge(with: NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
      .sink { _ in self.updatePasteButton() }
  }

  func lookUpWord(_ input: String) -> (word: String, indexPath: IndexPath)? {
    if let cleaned =
         (
          input.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { CharacterSet.whitespacesAndNewlines.contains($0.unicodeScalars.first!) })
            .first
         ).map(String.init)?.removeCharacters(from: .letters.inverted),
       !cleaned.isEmpty,
       let section = allWords!.firstIndex(where: { $0.letter == String(cleaned.first!) }) {

      let row: Int?
      if let match = allWords![section].words.firstIndex(of: cleaned) {
        row = match
      } else if let match = allWords![section].words.firstIndex(where: { ($0 + "s") == cleaned }) {
        row = match
      } else if let match = allWords![section].words.firstIndex(where: { ($0 + "es") == cleaned }) {
        row = match
      } else if let match = allWords![section].words.firstIndex(where: { ($0 + "ed") == cleaned }) {
        row = match
      } else if let match = allWords![section].words.firstIndex(where: { ($0 + "ing") == cleaned }) {
        row = match
        //      } else if let match = allWords![section].words.firstIndex(where: { $0.count > 2 && cleaned.starts(with: $0) }) {
        //        row = match
        //      } else if let match = allWords![section].words.firstIndex(where: { $0.count > 2 && $0.starts(with: cleaned) }) {
        //        row = match
      } else {
        row = nil
      }
      if let row = row {
        return (allWords![section].words[row], IndexPath(row: row, section: section))
      }
    }
    return nil
  }

  func openDetail(forRowAt indexPath: IndexPath) {
    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
    if navigationController?.topViewController != self {
      navigationController?.popToViewController(self, animated: false)
      UIView.performWithoutAnimation {
        self.tableView(tableView, didSelectRowAt: indexPath)
      }
    } else {
      self.tableView(tableView, didSelectRowAt: indexPath)
    }
  }

  func updatePasteButton() {
    if let copiedString = UIPasteboard.general.string,
       let (word, indexPath) = lookUpWord(copiedString) {
      if word != pasteLabel.text {
        pasteLabel.text = word
        pasteTarget = indexPath
      }
    } else {
      pasteTarget = nil
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    navigationController!.isToolbarHidden = false
  }


  @IBAction func pasteButtonTapped() {
    if let pasteTarget = pasteTarget {
      self.openDetail(forRowAt: pasteTarget)
      self.pasteTarget = nil
    }
  }

  // MARK: - UISearchResultsUpdatingr
  func updateSearchResults(for searchController: UISearchController) {
    guard let query = searchController.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return }
    guard let section = allWords!.firstIndex(where: { query.first == $0.letter.first }) else { return }
    if let row = allWords![section].words.firstIndex(where: { $0 > query }) {
      tableView.scrollToRow(at: IndexPath(row: row == 0 ? row : row - 1, section: section), at: .top, animated: false)
    }
  }

  @IBAction func goToRandomWord(_ sender: Any) {
    let lengths = allWords!.map(\.words.count)
    let totalLength = lengths.reduce(0, +)
    var row = Int.random(in: 0..<totalLength)
    var section = 0
    while row >= lengths[section] {
      row -= lengths[section]
      section += 1
    }
    openDetail(forRowAt: IndexPath(row: row, section: section))
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let detailVC = detailVC as? UINavigationController,
       let customVC = detailVC.topViewController as? ViewController {
      customVC.word = allWords![indexPath.section].words[indexPath.row]
      customVC.wordListVC = self
      self.showDetailViewController(detailVC, sender: self)
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
    let cell = tableView.dequeueReusableCell(withIdentifier: "WordRow", for: indexPath)
    cell.textLabel?.text = allWords![indexPath.section].words[indexPath.row]
    return cell
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    nil
  }

  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    allWords?.map { $0.letter.uppercased() }
  }
}
