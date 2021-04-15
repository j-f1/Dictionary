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
  }


  // MARK: - UISplitViewControllerDelegate
  func splitViewController(
    _ svc: UISplitViewController,
    topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
  ) -> UISplitViewController.Column {
    if let vc = (
      (svc.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first as? ViewController
    ) {
      return vc.word == nil ? .primary : .secondary
    }
    return .primary
  }
}
