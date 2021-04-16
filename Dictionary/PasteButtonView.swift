//
//  PasteButtonView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/15/21.
//

import UIKit

@IBDesignable
class PasteButtonView: UIButton {
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    layer.shadowColor = UIColor(named: "AccentColor")?.cgColor
    layer.shadowOpacity = 0.35
    layer.shadowOffset = .zero
    layer.shadowRadius = 10
  }


  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.height / 2
    layer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: bounds.height / 2, cornerHeight: bounds.height / 2, transform: nil)
  }

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(withDuration: 0.2) {
        if self.isHighlighted {
          self.layer.shadowRadius = 8
          self.layer.setAffineTransform(CGAffineTransform(scaleX: 0.95, y: 0.95))
        } else {
          self.layer.shadowRadius = 10
          self.layer.setAffineTransform(.identity)
        }
      }
    }
  }
}
