//
//  AboutView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/18/21.
//

import SwiftUI
import AboutScreen

struct AboutView: View {
  var body: some View {
    AboutScreen(
      copyrightYear: "2021",
      dependencies: [
        Dependency(
          "ZIPFoundation",
          url: "https://github.com/weichsel/ZIPFoundation",
          version: "0.9.12",
          license: Licenses.mit,
          licenseURL: "https://github.com/weichsel/ZIPFoundation/blob/0.9.12/LICENSE",
          description: "Effortless ZIP Handling in Swift"
        ),
        Dependency(
          "Defaults",
          url: "https://github.com/sindresorhus/Defaults",
          version: "4.2.1",
          license: Licenses.mit,
          licenseURL: "https://github.com/sindresorhus/Defaults/blob/4.2.1/license",
          description: Text("Swifty and modern ") + Text("UserDefaults").font(.system(.body, design: .monospaced))
        ),
      ]
    )
    .overlay(
      Color.systemGroupedBackground
        .frame(height: 50),
      alignment: .top
    )
    .padding(.top, -100)
    .navigationBarTitleDisplayMode(.large)
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    AboutView()
  }
}
