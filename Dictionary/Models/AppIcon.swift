//
//  AppIconSetting.swift
//  Dictionary
//
//  Created by Jed Fox on 4/18/21.
//

import SwiftUI
import Combine

struct AppIcon: Identifiable {
  let friendlyName: String
  let imageName: String
  let id: String?

  private static func imageName(for icon: Any?) -> String? {
    (
      (
        icon as? [String: Any]
      )?["CFBundleIconFiles"] as? [String]
    )?.first
  }

  public static var allIcons: [AppIcon] = {
    if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
       let alternateIcons = icons["CFBundleAlternateIcons"] as? [String: Any]
    {
      let primaryIcon: [AppIcon]? = imageName(for: icons["CFBundlePrimaryIcon"]).map {
        [AppIcon(friendlyName: "Default", imageName: $0, id: nil)]
      }
      return (primaryIcon ?? []) + alternateIcons.compactMap { (friendlyName, icon) in
        guard
          let iconList = icon as? [String: Any],
          let iconFiles = iconList["CFBundleIconFiles"] as? [String],
          let imageName = iconFiles.first
        else { return nil }
        return AppIcon(friendlyName: friendlyName, imageName: imageName, id: friendlyName)
      }
    } else {
      return []
    }
  }()

  public static var currentID: String? {
    UIApplication.shared.alternateIconName
  }
}
