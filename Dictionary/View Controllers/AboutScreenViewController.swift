//
//  AboutScreenViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/15/21.
//

import UIKit
import SwiftUI
import AboutScreen

class AboutScreenViewController: UIHostingController<AnyView> {
  required init?(coder: NSCoder) {
    super.init(coder: coder, rootView: AnyView(
      AboutScreen(
        copyrightYear: "2021",
        dependencies: [
          Dependency(
            "ZIPFoundation",
            url: "https://github.com/weichsel/ZIPFoundation",
            version: "0.9.12",
            license: .mit,
            licenseURL: "https://github.com/weichsel/ZIPFoundation/blob/0.9.12/LICENSE",
            description: "Effortless ZIP Handling in Swift"
          )
        ]
      )
    ))
  }
}
