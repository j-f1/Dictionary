//
//  AppIconSettingsView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/19/21.
//

import SwiftUI

struct AppIconChoice: View {
  let icon: AppIcon
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 15) {
      let size: CGFloat = 50
      Image(uiImage: UIImage(named: icon.imageName)!)
        .resizable()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size / 4.3, style: .continuous))
        .padding(.vertical, 5)
      Text(icon.friendlyName)
      Spacer()
      if isSelected {
        Image(systemName: "checkmark")
          .foregroundColor(.accentColor)
          .imageScale(.large)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(icon.friendlyName)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

struct AppIconSettingsView: View {
  @Binding var appIcon: String?
  var body: some View {
    List(AppIcon.allIcons) { icon in
      Button(action: { appIcon = icon.id }) {
        AppIconChoice(icon: icon, isSelected: icon.id == appIcon)
          .foregroundColor(.primary)
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationTitle("App Icon")
    .onChange(of: appIcon, perform: { value in
      UIApplication.shared.setAlternateIconName(value, completionHandler: { err in
        if let err = err {
          print(err)
          appIcon = AppIcon.currentID
        }
      })
    })
  }
}

struct AppIconSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AppIconSettingsView(appIcon: .constant(nil))
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}