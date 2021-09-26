//
//  WordCountLabel.swift
//  Dictionary
//
//  Created by Jed Fox on 9/26/21.
//

import UIKit

private let numberFormatter = { () -> NumberFormatter in
  let fmt = NumberFormatter()
  fmt.numberStyle = .decimal
  return fmt
}()

class WordCountLabel: UILabel {

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)

    textColor = .secondaryLabel
    font = UIFont.preferredFont(forTextStyle: .footnote)
    adjustsFontForContentSizeCategory = true
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)
    translatesAutoresizingMaskIntoConstraints = false
  }

  func update(from words: [WordLetter]) {
    let totalCount = words.reduce(0) { $0 + $1.words.count }
    if totalCount == 1 {
      text = "1 word"
    } else {
      text = "\(numberFormatter.string(from: totalCount as NSNumber)!) words"
    }
  }
}
