//
//  ViewController.swift
//  ShadowSNE
//
//  Created by Benjamin Erhart on 10.01.18.
//  Copyright © 2018 Guardian Project. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var serverTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var encryptionLb: UILabel!
    @IBOutlet weak var connectBt: UIButton!
    
    var fields = [UITextField]()

    let settings = UserDefaults.standard
    var server: String?
    var port: String?
    var password: String?
    var encryption: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        fields = [serverTF, portTF, passwordTF];

        server = settings.string(forKey: "server")
        port = settings.string(forKey: "port")
        password = settings.string(forKey: "password")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        serverTF.text = server
        portTF.text = port
        passwordTF.text = password
        encryption = settings.string(forKey: "encryption")
        encryptionLb.text = encryption

        connectBt.isEnabled = !(server ?? "").isEmpty && !(port ?? "").isEmpty
            && !(password ?? "").isEmpty && !(encryption ?? "").isEmpty
    }


    // MARK: UITextFieldDelegate

    public func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case portTF:
            port = textField.text
            settings.set(port, forKey: "port")
        case passwordTF:
            password = textField.text
            settings.set(password, forKey: "password")
        default:
            server = textField.text
            settings.set(server, forKey: "server")
        }

        connectBt.isEnabled = !(server ?? "").isEmpty && !(port ?? "").isEmpty
            && !(password ?? "").isEmpty && !(encryption ?? "").isEmpty
    }

    /**
     Handle text field next/done keyboard buttons.
    */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !textField.resignFirstResponder() {
            return false
        }

        if let index = fields.index(where: {$0 === textField}) {
            let index = fields.index(after: index)

            if index < fields.count {
                fields[index].becomeFirstResponder()
            }
        }

        return false
    }


    // MARK: Actions

    @IBAction func connect() {
        print("Connect!")
    }


    // MARK: Private

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
