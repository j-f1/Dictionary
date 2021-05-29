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

  var sectionOffset: Int { 0 }

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

  var words: [WordLetter]? {
    didSet {
      tableView?.reloadData()
    }
  }

  // MARK: - UISearchResultsUpdating
  func updateSearchResults(for searchController: UISearchController) {
    guard
      let query = searchController.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
      let words = words
    else { return }
    guard let section = words.firstIndex(where: { query.first == $0.letter.first }) else { return }
    if let row = words[section].words.firstIndex(where: { $0 > query }) {
      tableView.scrollToRow(at: IndexPath(row: row == 0 ? row : row - 1, section: section + sectionOffset), at: .top, animated: false)
    }
  }

  // MARK: - Table view data source

  func numberOfSections(in tableView: UITableView) -> Int {
    (words?.count ?? 0) + sectionOffset
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    words![section - sectionOffset].words.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.word, for: indexPath)
    cell.textLabel?.text = words![indexPath.section - sectionOffset].words[indexPath.row]
    return cell
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    nil
  }

  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    Array(repeating: "", count: sectionOffset) + (words?.map { $0.letter.uppercased() } ?? [])
  }
}
