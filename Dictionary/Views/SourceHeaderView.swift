//
//  SourceHeaderView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/26/21.
//

import SwiftUI
import LinkPresentation


struct Source: Codable {
  let isPseudonym: Bool
  let name: String
  let href: URL?
}

struct SourceHeaderView: View {
  let source: Source

  var body: some View {
    Text(source.name).font(.title2.bold())
    Text("(pseudonym)")
  }
}

struct SourceHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    SourceHeaderView(source: Source(isPseudonym: true, name: "Benjamin Vaughan Abbott", href: URL(string: "https://en.wikipedia.org/wiki/Benjamin_Vaughan_Abbott")))
  }
}
