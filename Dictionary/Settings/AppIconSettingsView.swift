//
//  AppIconSettingsView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/19/21.
//

import SwiftUI

struct AppIconChoice: View {
  let icon: AppIcon

  var body: some View {
    HStack(spacing: 15) {
      let size: CGFloat = 50
      Image(uiImage: UIImage(named: icon.imageName)!)
        .resizable()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size / 4.3, style: .continuous))
        .padding(.vertical, 5)
      Text(icon.friendlyName)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(icon.friendlyName)
  }
}

struct AppIconPickerView: View {
  @Binding var appIcon: String?
  var body: some View {
    Picker("App Icon", selection: $appIcon) {
      ForEach(AppIcon.allIcons) { icon in
        AppIconChoice(icon: icon)
          .foregroundColor(.primary)
          .tag(icon.id)
      }
    }
    .pickerStyle(.inline)
    .onChange(of: appIcon, perform: { value in
      guard value != UIApplication.shared.alternateIconName else { return }
      UIApplication.shared.setAlternateIconName(value, completionHandler: { err in
        if let err = err {
          print(err)
          appIcon = AppIcon.currentID
        }
      })
    })
  }
}

struct AppIconPickerView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AppIconPickerView(appIcon: .constant(nil))
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}
