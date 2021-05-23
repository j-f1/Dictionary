//
//  SourceTableViewController.swift
//  Dictionary
//
//  Created by Jed Fox on 4/26/21.
//

import UIKit
import SafariServices

fileprivate enum CellIdentifier {
  static let word = "WordRow"
}

class SourceTableViewController: UITableViewController {

  var source: Source?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    openLinkButton.isEnabled = !(source?.meta?.href).isNil
    navigationItem.title = source?.meta?.name
    tableView.reloadData()
  }

  @IBOutlet weak var openLinkButton: UIBarButtonItem!
  @IBAction func openLink(_ sender: Any) {
    let vc = SFSafariViewController(url: source!.meta!.href!)
    vc.modalPresentationStyle = .pageSheet
    vc.dismissButtonStyle = .close
    vc.preferredControlTintColor = UIColor(named: "AccentColor")
    present(vc, animated: true, completion: nil)
  }

  @IBAction func dismiss(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return source?.words.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.word, for: indexPath)

    cell.textLabel?.text = source?.words[indexPath.row]

    return cell
  }

  /*
   // Override to support editing the table view.
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
   if editingStyle == .delete {
   // Delete the row from the data source
   tableView.deleteRows(at: [indexPath], with: .fade)
   } else if editingStyle == .insert {
   // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }
   }
   */

  /*
   // Override to support rearranging the table view.
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

   }
   */

  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the item to be re-orderable.
   return true
   }
   */

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */

}
