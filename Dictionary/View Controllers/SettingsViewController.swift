//
//  SettingsViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/15/21.
//

import UIKit
import SwiftUI
import AboutScreen

class SettingsViewController: UIHostingController<SettingsView> {
  init() {
    super.init(rootView: SettingsView {})
    self.rootView = SettingsView { self.dismiss(animated: true, completion: nil) }
    self.modalPresentationStyle = .formSheet
  }
  
  @objc required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
