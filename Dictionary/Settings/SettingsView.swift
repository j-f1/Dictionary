//
//  SettingsView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/17/21.
//

import SwiftUI
import AboutScreen
import Defaults

struct SettingsView: View {
  let onDismiss: () -> ()

  @Default(.watchPasteboard) private var watchPasteboard

  var body: some View {
    NavigationView {
      List {

        Section(footer: Text("Look for a word to define on your clipboard when you open the app").padding(.horizontal)) {
          Toggle("Detect Copied Words", isOn: $watchPasteboard)
        }

        NavigationLink("About", destination: Group {
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
          .overlay(
            Color.systemGroupedBackground
              .frame(height: 50),
            alignment: .top
          )
          .padding(.top, -100)
          .navigationBarTitleDisplayMode(.large)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done", action: onDismiss)
            }
          }
        })
      }
      .listStyle(InsetGroupedListStyle())
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: onDismiss)
        }
      }
    }.navigationViewStyle(StackNavigationViewStyle())
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView {}
  }
}
