//
//  Source.swift
//  Dictionary
//
//  Created by Jed Fox on 4/27/21.
//

import Foundation

struct Source {
  let words: [String]
  let meta: Meta?

  struct Meta: Codable {
    let isPseudonym: Bool
    let name: String
    let href: URL?
  }
}

extension Source {
}
