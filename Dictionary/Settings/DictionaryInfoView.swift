//
//  DictionaryInfoView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/18/21.
//

import SwiftUI

struct DictionaryInfoView: View {
  var body: some View {
    Form {
      Section {
        HTMLView(style: "text-align: center; font: \(UIFont.systemFontSize * 1.2)px ui-serif", """
          Webster's Revised Unabridged Dictionary<br>
          Version published 1913<br>
          by the C. & G. Merriam Co.<br>
          Springfield, Mass.<br>
          Under the direction of<br>
          Noah Porter, D.D., LL.D.
        """)
      }
      Section {
        HTMLView("The content of this app comes from the 1913 edition of <a href='https://en.wikipedia.org/wiki/Webster%27s_Dictionary#1913_edition'>Webster’s Dictionary</a>.")
        HTMLView("The dictionary was digitized as part of the <a href='https://gcide.gnu.org.ua'>GCIDE</a> project maintained by Patrick J. Cassidy and Sergey Poznyakoff.")
        HTMLView("""
          The GCIDE data was further processed into HTML using <a href="https://github.com/ponychicken/WebsterParser"><code>WebsterParser</code></a>, written by <a href="https://github.com/ponychicken">ponychicken</a>, <a href="https://thejeffbyrnes.com">Jeff Byrnes</a>, myself, and all the other <a href="https://github.com/ponychicken/WebsterParser/graphs/contributors">contributors</a>.
        """)
        HTMLView("""
          This app is free software, and you can grab its source code <a href="https://github.com/j-f1/Dictionary">on GitHub</a>!
        """)
      }
    }
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
