//
//  CSSColor.swift
//  Dictionary
//
//  Created by Jed Fox on 4/27/21.
//

import UIKit

extension UIColor {
  var cssValue: String {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    UIColor.systemBlue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return "rgba(\(red * 100)%, \(green * 100)%, \(blue * 100)%, \(alpha * 100))"
  }
}
