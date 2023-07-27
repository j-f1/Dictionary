//
//  DictionaryInfoView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/18/21.
//

import SwiftUI

@MainActor
struct DictionaryInfoView: View {
  var body: some View {
    Form {
      Section {
        Text("""
        The content of this app comes from the 1913 edition of [Webster’s Dictionary](https://en.wikipedia.org/wiki/Webster%27s_Dictionary#1913_edition).

        The dictionary was digitized as part of the [GCIDE](https://gcide.gnu.org.ua) project maintained by Patrick J. Cassidy and Sergey Poznyakoff.

        The GCIDE data was further processed into HTML using [`WebsterParser`](https://github.com/ponychicken/WebsterParser), written by [ponychicken](https://github.com/ponychicken), [Jeff Byrnes](https://thejeffbyrnes.com), myself, and all the other [contributors](https://github.com/ponychicken/WebsterParser/graphs/contributors).

        This app is free software, and you can grab its source code [on GitHub](https://github.com/j-f1/Dictionary)!
        """)
      } header: {
        Text("""
        Webster's Revised Unabridged Dictionary
        Version published 1913
        by the C. & G. Merriam Co.
        Springfield, Mass.
        Under the direction of
        Noah Porter, D.D., LL.D.
        """)
        .padding(.bottom)
        .padding(.bottom)
        .frame(maxWidth: .infinity)
        .font(.system(.title3, design: .serif))
        .multilineTextAlignment(.center)
        .textCase(nil)
        .foregroundColor(.primary)
        .textSelection(.enabled)
      }
    }
    .textSelection(.enabled)
    .navigationTitle("About Webster’s Dictionary")
  }
}

struct DictionaryInfoView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      DictionaryInfoView()
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}
