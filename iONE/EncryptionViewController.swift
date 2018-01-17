//
//  EncryptionViewController.swift
//  iONE
//
//  Created by Benjamin Erhart on 11.01.18.
//  Copyright © 2018 Guardian Project. All rights reserved.
//

import UIKit

class EncryptionViewController: UITableViewController {

    static let encryptions = ["AES-256-CFB", "AES-192-CFB", "AES-128-CFB", "CHACHA20", "RC4-MD5", "SALSA20"]

    var mainVC: MainViewController?

    var currentVal: String?
    var currentIdx: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let vcs = navigationController?.viewControllers {
            mainVC = vcs[vcs.count - 2] as? MainViewController
        }

        currentVal = mainVC?.encryption
        currentIdx = EncryptionViewController.encryptions.index(where: {$0 == currentVal})
    }


    // MARK: UITableViewDataSource

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EncryptionViewController.encryptions.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell") {

            let label = cell.viewWithTag(1) as! UILabel
            label.text = EncryptionViewController.encryptions[indexPath.row]

            cell.accessoryType = currentIdx == indexPath.row ? .checkmark : .none

            return cell
        }

        // This would only happen, if we fucked up the cell identifier.
        return UITableViewCell()
    }


    // MARK: UITableViewDelegate

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentIdx = indexPath.row
        currentVal = EncryptionViewController.encryptions[currentIdx!]
        mainVC?.encryption = currentVal

        navigationController?.popViewController(animated: true)
    }
}
