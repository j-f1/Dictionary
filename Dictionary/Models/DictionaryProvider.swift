//
//  DictionaryProvider.swift
//  Dictionary
//
//  Created by Jed Fox on 4/17/21.
//

import Foundation
import ZIPFoundation

enum PendingResult<T> {
  case none
  case pending(DispatchWorkItem)
  case done(T)
}

extension Bundle {
  func json(named name: String) -> Data? {
    if let url = self.url(forResource: name, withExtension: "json") {
      return try? Data(contentsOf: url)
    }
    return nil
  }
}

class DictionaryProvider {
  static let shared = DictionaryProvider()

  private var archives: [String: ZIPFoundation.Archive] = [:]
  private var sources: PendingResult<[String: Source]> = .none

  private static let decoder = JSONDecoder()

  static func sortWords(_ data: [WordLetter]) -> [WordLetter] {
    Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ'-").map { name in
      data.first { $0.letter.uppercased() == String(name) }!
    }
  }

  static func loadWords(from fileName: String) -> [WordLetter] {
    sortWords(try! decoder.decode([WordLetter].self, from: Bundle.main.json(named: fileName)!))
  }

  func loadSources(callback: @escaping ([String: Source]) -> ()) {
    if case .done(let result) = sources {
      callback(result)
      return
    } else if case .pending(let workItem) = sources {
      workItem.notify(queue: .main) {
        guard case .done(let result) = self.sources else { fatalError() }
        callback(result)
      }
    }
    let workItem = DispatchWorkItem {
      let words = try! Self.decoder.decode([String: [WordLetter]].self, from: Bundle.main.json(named: "sources-words")!)
      let metas = try! Self.decoder.decode([String: Source.Meta].self, from: Bundle.main.json(named: "sources-meta")!).values
      let result = Dictionary(uniqueKeysWithValues: words.map { (source, words) in
        (source, Source(words: words.map { .init(letter: $0.letter.lowercased(), words: $0.words) }, meta: metas.first { $0.name == source }))
      })
      self.sources = .done(result)
      DispatchQueue.main.async {
        callback(result)
      }
    }
    sources = .pending(workItem)
    DispatchQueue.global(qos: .utility).async(execute: workItem)
  }

  subscript(source source: String, callback: @escaping (Source?) -> ()) -> () {
    get {
      loadSources { callback($0[source]) }
    }
  }

  subscript(word word: String, callback: @escaping (Data) -> ()) -> () {
    get {
      DispatchQueue.global(qos: .userInitiated).async { [self] in
        let key = String(word.first!)
        if archives[key] == nil {
          archives[key] = ZIPFoundation.Archive(
            data: try! Data(
              contentsOf: Bundle.main.url(forResource: key, withExtension: "zip")!,
              options: .alwaysMapped
            ),
            accessMode: .read,
            preferredEncoding: .utf8
          )
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

