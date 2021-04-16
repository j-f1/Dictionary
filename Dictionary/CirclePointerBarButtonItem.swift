//
//  CirclePointerBarButtonItem.swift
//  Dictionary
//
//  Created by Jed Fox on 4/16/21.
//

import UIKit

func makeCirclePointerButton(_ image: UIImage, label: String, action: @escaping () -> ()) -> UIButton {
  let button = UIButton(type: .system)
  button.setImage(image.withConfiguration(UIImage.SymbolConfiguration(scale: .large)), for: .normal)
  button.accessibilityLabel = label
  button.addAction(UIAction { _ in action() }, for: .primaryActionTriggered)
  button.sizeToFit()

  button.isPointerInteractionEnabled = true
  button.pointerStyleProvider = { button, proposedEffect, proposedShape in
    UIPointerStyle(
      effect: .highlight(proposedEffect.preview),
      shape: .roundedRect(
        button.convert(button.bounds.insetBy(dx: -7, dy: -7), to: proposedEffect.preview.target.container),
        radius: button.bounds.height + 14
      )
    )
  }
  return button
}
