//
//  EncryptionViewController.swift
//  ShadowSNE
//
//  Created by Benjamin Erhart on 11.01.18.
//  Copyright © 2018 Guardian Project. All rights reserved.
//

import UIKit

class EncryptionViewController: UITableViewController {

    let encryptions = ["AES-256-CFB", "AES-192-CFB", "AES-128-CFB", "CHACHA20", "RC4-MD5", "SALSA20"]

    let settings = UserDefaults.standard
    var currentVal: String?
    var currentIdx: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        currentVal = settings.string(forKey: "encryption")
        currentIdx = encryptions.index(where: {$0 == currentVal})
    }


    // MARK: UITableViewDataSource

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return encryptions.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell") {

            let label = cell.viewWithTag(1) as! UILabel
            label.text = encryptions[indexPath.row]

            cell.accessoryType = currentIdx == indexPath.row ? .checkmark : .none

            return cell
        }

        // This would only happen, if we fucked up the cell identifier.
        return UITableViewCell()
    }


    // MARK: UITableViewDelegate

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentIdx = indexPath.row
        currentVal = encryptions[currentIdx!]
        settings.set(currentVal, forKey: "encryption")

        navigationController?.popViewController(animated: true)
    }
}
