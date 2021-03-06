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
      words = source?.words
      navigationItem.title = source?.meta?.name
      navigationItem.rightBarButtonItem?.isEnabled = source?.meta?.href != nil
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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    DispatchQueue.main.async { [self] in
      tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    source = nil
    searchController.searchBar.text = ""
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 0
    }
    return super.tableView(tableView, numberOfRowsInSection: section)
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal

    if section == 0,
       let count = source?.words.map({ $0.words.count }).reduce(0, +),
       let formatted = formatter.string(from: count as NSNumber) {
      return "\(formatted) word\(count == 1 ? "" : "s")"
    }
    return super.tableView(tableView, titleForHeaderInSection: section)
  }

  @IBAction func dismiss(_: Any) {
    presentingViewController?.dismiss(animated: true, completion: nil)
  }

  @IBAction func pin(_ sender: Any) {
    if let detailVC = detailVC,
       let source = source {
      detailVC.wordListVC.pin(source)
      self.dismiss(sender)
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    detailVC?.navigateDictionary(to: source!.words[indexPath.section - 1].words[indexPath.row])
    self.dismiss(tableView)
  }
}
