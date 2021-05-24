//
//  SourceTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/26/21.
//

import SwiftUI
import SafariServices

fileprivate enum CellIdentifier {
  static let word = "WordRow"
}

class SourceTableViewController: WordListController, UITableViewDelegate {
  var source: Source? {
    didSet {
      loadingView?.isHidden = source != nil
      allWords = source?.words
      navigationItem.title = source?.meta?.name
      navigationItem.rightBarButtonItem?.isEnabled = source?.meta?.href != nil
//          self.rootView = AnyView(SourceView(source: source, onOpenLink: self.open(link:), onDismiss: { word in
//            self.dismiss(self.rootView)
//            if let word = word,
//               let presenter = self.presentingViewController as? SplitViewController,
//               let detail = presenter.detailVC {
//              detail.navigateDictionary(to: word)
//            }
//          }))
    }
  }

  var detailVC: DetailViewController?

  @IBOutlet weak var loadingView: UIView!

  override var sectionOffset: Int { 1 }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    loadingView?.isHidden = source != nil
    navigationItem.searchController = searchController
    searchController.searchBar.searchBarStyle = .minimal
    navigationItem.hidesSearchBarWhenScrolling = false
  }


  @IBAction func openURL(_: Any) {
    let vc = SFSafariViewController(url: source!.meta!.href!)
    vc.modalPresentationStyle = .pageSheet
    vc.dismissButtonStyle = .close
    vc.preferredControlTintColor = UIColor(named: "AccentColor")
    present(vc, animated: true, completion: nil)
  }

  override func viewDidDisappear(_ animated: Bool) {
    source = nil
    navigationItem.title = "Loading…"
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 0
    }
    return super.tableView(tableView, numberOfRowsInSection: section)
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0,
       let count = source?.words.map({ $0.words.count }).reduce(0, +) {
      return "\(count) word\(count == 1 ? "" : "s")"
    }
    return super.tableView(tableView, titleForHeaderInSection: section)
  }

  @IBAction func dismiss(_: Any) {
    presentingViewController?.dismiss(animated: true, completion: nil)
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    detailVC?.navigateDictionary(to: source!.words[indexPath.section - 1].words[indexPath.row])
    self.dismiss(tableView)
  }
}
