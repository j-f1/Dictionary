//
//  CleanString.swift
//  Dictionary
//
//  Created by Jed Fox on 4/17/21.
//

import Foundation

extension String {
  func removeCharacters(from forbiddenChars: CharacterSet) -> String {
    let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
    return String(String.UnicodeScalarView(passed))
  }
}

func find(query: String, in allWords: [WordLetter]) -> (word: String, indexPath: IndexPath)? {
  if let cleaned =
      (
        query.lowercased()
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .split(whereSeparator: { CharacterSet.whitespacesAndNewlines.contains($0.unicodeScalars.first!) })
          .first
      ).map(String.init)?.removeCharacters(from: CharacterSet.letters.inverted),
     !cleaned.isEmpty,
     let section = allWords.firstIndex(where: { $0.letter == String(cleaned.first!) }) {

    let row: Int?
    if let match = allWords[section].words.firstIndex(of: cleaned) {
      row = match
    } else if let match = allWords[section].words.firstIndex(where: { ($0 + "s") == cleaned }) {
      row = match
    } else if let match = allWords[section].words.firstIndex(where: { ($0 + "es") == cleaned }) {
      row = match
    } else if let match = allWords[section].words.firstIndex(where: { ($0 + "ed") == cleaned }) {
      row = match
    } else if let match = allWords[section].words.firstIndex(where: { ($0 + "ing") == cleaned }) {
      row = match
//      } else if let match = allWords[section].words.firstIndex(where: { $0.count > 2 && cleaned.starts(with: $0) }) {
//        row = match
//      } else if let match = allWords[section].words.firstIndex(where: { $0.count > 2 && $0.starts(with: cleaned) }) {
//        row = match
    } else {
      row = nil
    }
    if let row = row {
      return (allWords[section].words[row], IndexPath(row: row, section: section))
    }
  }
  return nil
}
