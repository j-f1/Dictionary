//
//  WordsTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit

class WordsTableViewController: UITableViewController, UISearchResultsUpdating {

  let searchController = UISearchController(searchResultsController: nil)

  var allWords: [WordLetter]!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem

    searchController.searchResultsUpdater = self
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.automaticallyShowsCancelButton = false
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.searchBarStyle = .prominent
    searchController.searchBar.returnKeyType = .done
    searchController.searchBar.enablesReturnKeyAutomatically = false
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.largeTitleDisplayMode = .never // work around bug
  }

  // MARK: - UISearchResultsUpdatingr
  func updateSearchResults(for searchController: UISearchController) {
    guard let query = searchController.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return }
    guard let section = allWords.firstIndex(where: { query.first == $0.letter.first }) else { return }
    if let row = allWords[section].words.firstIndex(where: { $0 > query }) {
      tableView.scrollToRow(at: IndexPath(row: row == 0 ? row : row - 1, section: section), at: .top, animated: false)
    }
  }


  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    allWords.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    allWords[section].words.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "WordRow", for: indexPath)
    cell.textLabel?.text = allWords[indexPath.section].words[indexPath.row]
    return cell
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    nil
  }

  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    allWords.map { $0.letter.uppercased() }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */

}
