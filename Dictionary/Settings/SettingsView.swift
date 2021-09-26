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
  @State var appIcon = AppIcon.currentID

  var body: some View {
    NavigationView {
      List {
        Section(footer: Text("Copy a word onto your clipboard and open this app to view the definition in one tap")) {
          Toggle("Detect Copied Words", isOn: $watchPasteboard)
        }

        AppIconPickerView(appIcon: $appIcon)

        NavigationLink("About This App", destination: AboutView())
        NavigationLink("About Webster’s Dictionary", destination: DictionaryInfoView())
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: onDismiss)
        }
      }
    }.navigationViewStyle(.stack)
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView {}
  }
}
