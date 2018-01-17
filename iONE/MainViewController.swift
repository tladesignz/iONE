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
    var session: NETunnelProviderSession?
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

                // Where are these from? Must be a residue from development.
                // We don't support multiple configurations, yet.
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

            self.session = self.manager?.connection as? NETunnelProviderSession

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

        // Displayed in Settings app. Update to latest values.
        conf?.serverAddress = "\(self.server!):\(self.port!)"

        // Update latest configuration changes.
        manager?.protocolConfiguration = conf

        // Set VPN configuration enabled. (Gets a checkmark in Settings app.)
        manager?.isEnabled = true

        manager?.saveToPreferences() { (error) -> Void in
            if let error = error as? NEVPNError {
                // Most times: User didn't allow to store or didn't enter passphrase/TouchID/FaceID
                // correctly. But could be unable to write or similar.

                // Don't show an error here - user already saw a UIAlertController and maybe even
                // the passphrase scene or similar.
                if error.errorCode != 5 /* "permission denied" */ {
                    self.errorAlert(error)
                }

                return
            }

            do {
                try self.session?.startVPNTunnel()
            } catch let error {
                self.errorAlert(error)
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

    private func errorAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
