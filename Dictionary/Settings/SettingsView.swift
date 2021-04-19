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

        NavigationLink("About This App", destination: AboutView())
        NavigationLink("About Webster’s Dictionary", destination: DictionaryInfoView())
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
