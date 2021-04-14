//
//  ContentView.swift
//  Dictionary
//
//  Created by Jed Fox on 4/13/21.
//

import SwiftUI

let allWords = try! JSONSerialization.jsonObject(
  with: Data(
    contentsOf: Bundle.main.url(
      forResource: "word-list",
      withExtension: "json"
    )!
  )
) as! [String]

struct ContentView: View {
  var body: some View {
    NavigationView {
      List(allWords, id: \.self) { word in
        NavigationLink(word, destination: Text("detail"))
      }
      .navigationTitle("Dictionary")
      .toolbar {
        ToolbarItem(placement: .status) {
          Text("\(allWords.count) words")
            .foregroundColor(.secondary)
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
