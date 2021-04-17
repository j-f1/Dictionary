//
//  CirclePointerBarButtonItem.swift
//  Dictionary
//
//  Created by Jed Fox on 4/16/21.
//

import UIKit

fileprivate func makeButton(_ image: UIImage, label: String, action: @escaping () -> ()) -> UIButton {
  let button = UIButton(type: .system)
  button.setImage(image.withConfiguration(UIImage.SymbolConfiguration(scale: .large)), for: .normal)
  button.accessibilityLabel = label
  button.addAction(UIAction { _ in action() }, for: .primaryActionTriggered)
  button.sizeToFit()

  button.isPointerInteractionEnabled = true
  return button
}

func makeCirclePointerButton(_ image: UIImage, label: String, action: @escaping () -> ()) -> UIButton {
  let button = makeButton(image, label: label, action: action)
  button.pointerStyleProvider = { button, proposedEffect, proposedShape in
    UIPointerStyle(
      effect: .highlight(proposedEffect.preview),
      shape: .roundedRect(
        button.convert(button.bounds.insetBy(dx: -10, dy: -10), to: proposedEffect.preview.target.container),
        radius: button.bounds.height + 20
      )
    )
  }
  return button
}
