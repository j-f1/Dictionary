//
//  DictionaryProvider.swift
//  Dictionary
//
//  Created by Jed Fox on 4/17/21.
//

import Foundation
import ZIPFoundation

class DictionaryProvider {
  static let shared = DictionaryProvider()

  private var archives: [String: ZIPFoundation.Archive] = [:]

  static func loadWords(from fileName: String) -> [WordLetter] {
    let data = try! JSONDecoder().decode([WordLetter].self, from: Data(contentsOf: Bundle.main.url(forResource: fileName, withExtension: "json")!))

    return Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ'-").map { name in
      data.first { $0.letter.uppercased() == String(name) }!
    }
  }

  subscript(_ word: String, callback: @escaping (Data) -> ()) -> () {
    get {
      DispatchQueue.global(qos: .userInitiated).async { [self] in
        let key = String(word.first!)
        if archives[key] == nil {
          archives[key] = ZIPFoundation.Archive(
            url: Bundle.main.url(forResource: key, withExtension: "zip")!,
            accessMode: .read
          )!
        }
        var data = Data()
        if let archive = archives[key],
           let entry = archive["\(word).html"] {
          _ = try! archive.extract(entry) { chunk in
            data += chunk
          }
          DispatchQueue.main.async {
            callback(data)
          }
        }
      }
    }
  }
}

