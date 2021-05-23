//
//  SplitViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/15/21.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    self.delegate = self
    self.preferredPrimaryColumnWidthFraction = 3/8
    self.minimumPrimaryColumnWidth = 200
  }

  var detailVC: DetailViewController? {
    (self.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first as? DetailViewController
  }

  func splitViewController(
    _ svc: UISplitViewController,
    topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
  ) -> UISplitViewController.Column {
    return detailVC?.word == nil ? .primary : .secondary
  }
}
