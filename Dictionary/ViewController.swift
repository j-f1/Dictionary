//
//  ViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import UIKit

class ViewController: UIViewController {

  var word: String? {
    didSet {
      self.navigationItem.title = word
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let nc = navigationController,
       nc.viewControllers.contains(self) {
      self.word = nil
    }
  }
}

