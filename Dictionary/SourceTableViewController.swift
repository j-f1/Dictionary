//
//  SourceTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/26/21.
//

import SwiftUI
import SafariServices

fileprivate enum CellIdentifier {
  static let word = "WordRow"
}

class SourceTableViewController: UIHostingController<AnyView> {
  var source: NotActuallyAPromise<Source?>? {
    didSet {
      if let source = source {
        source.fetchResult { source in
          guard let source = source else { return }
          self.rootView = AnyView(SourceView(source: source, onOpenLink: self.open(link:), onDismiss: { word in
            self.dismiss(self.rootView)
            if let word = word,
               let presenter = self.presentingViewController as? SplitViewController,
               let detail = presenter.detailVC {
              detail.navigateDictionary(to: word)
            }
          }))

        }
      }
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder, rootView: AnyView(EmptyView()))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func open(link url: URL) {
    let vc = SFSafariViewController(url: url)
    vc.modalPresentationStyle = .pageSheet
    vc.dismissButtonStyle = .close
    vc.preferredControlTintColor = UIColor(named: "AccentColor")
    present(vc, animated: true, completion: nil)
  }

  @IBAction func dismiss(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
  // MARK: - Table view data source

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */

}

struct SourceView: View {
  let source: Source
  let onOpenLink: (URL) -> ()
  let onDismiss: (String?) -> ()

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("\(source.words.count) word\(source.words.count == 1 ? "" : "s")")) {
          ForEach(source.words, id: \.self) { word in
            Button(action: { onDismiss(word) }) {
              NavigationLink(word, destination: EmptyView())
            }.accentColor(.primary)
          }
        }
      }
      .listStyle(GroupedListStyle())
      .navigationTitle(source.meta!.name)
      .navigationBarItems(
        leading: Button("Done") { onDismiss(nil) },
        trailing: Group {
          if let url = source.meta?.href {
            Button(action: { onOpenLink(url) }) {
              Image("wikipedia")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            }.buttonStyle(BorderlessButtonStyle())
          }
        }
      )
    }
  }
}

struct SourceView_Previews: PreviewProvider {
  static var previews: some View {
    SourceView(source: Source(words: ["A", "Aback", "Word", "Another"], meta: .init(isPseudonym: false, name: "William Shakespeare", href: URL(string: "https://en.wikipedia.org/wiki/William_Shakespeare"))), onOpenLink: {_ in }, onDismiss: { _ in })
  }
}
