//
//  WordLetter.swift
//  Dictionary
//
//  Created by Jed Fox on 4/27/21.
//

import Foundation

struct WordLetter: Decodable {
  let letter: String
  let words: [String]

  init(letter: String, words: [String]) {
    self.letter = letter
    self.words = words
  }

  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    letter = try container.decode(String.self)
    words = try container.decode([String].self)
  }
}
