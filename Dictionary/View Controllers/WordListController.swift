//
//  WordListController.swift
//  Dictionary
//
//  Created by Jed Fox on 5/23/21.
//

import UIKit

fileprivate enum CellIdentifier {
  static let word = "WordRow"
}

class WordListController: UIViewController, UITableViewDataSource, UISearchResultsUpdating {

  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    searchController.searchResultsUpdater = self
    tableView.dataSource = self
  }

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

  var allWords: [WordLetter]? {
    didSet {
      tableView.reloadData()
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
}
