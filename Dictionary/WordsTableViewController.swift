//
//  WordsTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit

func loadWords(from url: URL) -> [WordLetter] {
  let data = try! JSONDecoder().decode([WordLetter].self, from: Data(contentsOf: url))

  return Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ'-").map { name in
    data.first { $0.letter.uppercased() == String(name) }!
  }
}


class WordsTableViewController: UITableViewController, UISearchResultsUpdating, UISplitViewControllerDelegate {

  let searchController = UISearchController(searchResultsController: nil)

  lazy var detailVC = {
    self.splitViewController?.viewController(for: .secondary) ?? self.storyboard?.instantiateViewController(identifier: "DetailVC")
  }()

  var allWords: [WordLetter]? { didSet { tableView.reloadData() } }

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
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.titleView = searchController.searchBar
    navigationController?.setToolbarHidden(false, animated: true)

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
    let path = IndexPath(row: row, section: section)
    tableView.selectRow(at: path, animated: true, scrollPosition: .middle)
    self.tableView(tableView, didSelectRowAt: path)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let detailVC = detailVC as? UINavigationController,
       let customVC = detailVC.topViewController as? ViewController {
      customVC.word = allWords![indexPath.section].words[indexPath.row]
      self.showDetailViewController(detailVC, sender: self)
    }
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    allWords?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    allWords![section].words.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "WordRow", for: indexPath)
    cell.textLabel?.text = allWords![indexPath.section].words[indexPath.row]
    return cell
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    nil
  }

  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    allWords?.map { $0.letter.uppercased() }
  }

   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   }
}
