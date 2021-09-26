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
      titleLabel.text = navigationItem.title
      wikipediaButton.isEnabled = source?.meta?.href != nil

      if let words = source?.words {
        countLabel.update(from: words)
      }
    }
  }

  var detailVC: DetailViewController?

  @IBOutlet weak var loadingView: UIView!
  @IBOutlet weak var wikipediaButton: UIBarButtonItem!
  @IBOutlet weak var doneButton: UIBarButtonItem!

  private let titleLabel = UILabel()
  private let countLabel = WordCountLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    loadingView?.isHidden = source != nil
    navigationItem.searchController = searchController
    searchController.searchBar.searchBarStyle = .prominent
    doneButton.customView = UIButton(type: .close, primaryAction: UIAction { [weak self] in self?.dismiss($0) })
    titleLabel.font = UINavigationBarAppearance().titleTextAttributes[.font] as? UIFont
    let stack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
    stack.axis = .vertical
    stack.alignment = .center
    navigationItem.titleView = stack
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
    detailVC?.navigateDictionary(to: source!.words[indexPath.section].words[indexPath.row])
    self.dismiss(tableView)
  }
}
