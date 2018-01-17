//
//  ViewController.swift
//  iONE
//
//  Created by Benjamin Erhart on 10.01.18.
//  Copyright © 2018 Guardian Project. All rights reserved.
//

import UIKit
import NetworkExtension

class MainViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var serverTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var encryptionLb: UILabel!
    @IBOutlet weak var connectBt: UIButton!
    
    var fields = [UITextField]()

    var manager: NETunnelProviderManager?
    var conf: NETunnelProviderProtocol?
    var server: String?
    var port: String?
    var password: String?
    var encryption: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        fields = [serverTF, portTF, passwordTF];

        NETunnelProviderManager.loadAllFromPreferences() { (managers, error) -> Void in
            if let managers = managers, managers.count > 0 {
                self.manager = managers[0]
                self.conf = self.manager?.protocolConfiguration as? NETunnelProviderProtocol

                if managers.count > 1 {
                    var i = 0
                    for m in managers {
                        if i > 0 {
                            m.removeFromPreferences()
                        }
                        i += 1
                    }
                }
            }
            else {
                self.manager = NETunnelProviderManager()
                self.manager?.localizedDescription = "ShadowSocks"

                self.conf = NETunnelProviderProtocol()
                self.conf?.providerBundleIdentifier = "com.netzarchitekten.iONE.Ext"
                self.conf?.disconnectOnSleep = false
            }

            self.server = self.conf?.providerConfiguration?["server"] as? String
            self.port = self.conf?.providerConfiguration?["port"] as? String
            self.password = self.conf?.providerConfiguration?["password"] as? String
            self.encryption = self.conf?.providerConfiguration?["encryption"] as? String

            self.render()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        render()
    }


    // MARK: UITextFieldDelegate

    public func textFieldDidEndEditing(_ textField: UITextField) {
        port = portTF.text
        password = passwordTF.text
        server = serverTF.text

        conf?.providerConfiguration = [
            "server": self.server!,
            "port": self.port!,
            "password": self.password!,
            "encryption": self.encryption ?? "",
        ]

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

        conf?.serverAddress = "\(self.server!):\(self.port!)"

        manager?.protocolConfiguration = conf

        manager?.saveToPreferences() { (error) -> Void in
            if let error = error as? NEVPNError {
                print("Error: \(error)")
            }
        }
    }


    // MARK: Private

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func render() {
        serverTF.text = server
        portTF.text = port
        passwordTF.text = password
        encryptionLb.text = encryption

        connectBt.isEnabled = !(server ?? "").isEmpty && !(port ?? "").isEmpty
            && !(password ?? "").isEmpty && !(encryption ?? "").isEmpty
    }
}
