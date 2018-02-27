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
    @IBOutlet weak var statusLb: UILabel!
    
    var fields = [UITextField]()

    var manager: NETunnelProviderManager?
    var session: NETunnelProviderSession?
    var conf: NETunnelProviderProtocol?

    var server: String? {
        get {
            return conf?.providerConfiguration?["server"] as? String
        }
        set(newServer) {
            conf?.providerConfiguration?["server"] = newServer
        }
    }

    var port: String? {
        get {
            return conf?.providerConfiguration?["port"] as? String
        }
        set(newPort) {
            conf?.providerConfiguration?["port"] = newPort
        }
    }

    var password: String? {
        get {
            return conf?.providerConfiguration?["password"] as? String
        }
        set(newPassword) {
            conf?.providerConfiguration?["password"] = newPassword
        }
    }

    var encryption: String? {
        get {
            return conf?.providerConfiguration?["encryption"] as? String
        }
        set(newEncryption) {
            conf?.providerConfiguration?["encryption"] = newEncryption
        }
    }

    private lazy var tap: UITapGestureRecognizer? = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        return tap
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        fields = [serverTF, portTF, passwordTF];

        // Load configuration from store. Use only the first one, create one, if nothing there, yet.
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

            self.render()
            self.statusDidChange(nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Helps to dismiss keyboard, when user taps in empty area.
        if let tap = tap {
            view.addGestureRecognizer(tap)
        }

        // Receive notifications about extension lifecycle.
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange),
                                               name: .NEVPNStatusDidChange, object: nil)

        render()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let tap = tap {
            view.removeGestureRecognizer(tap)
        }

        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UITextFieldDelegate

    /**
     Handle text field data entry.
    */
    public func textFieldDidEndEditing(_ textField: UITextField) {
        port = portTF.text
        password = passwordTF.text
        server = serverTF.text

        conf?.providerConfiguration = [
            "server": self.server ?? "",
            "port": self.port ?? "",
            "password": self.password ?? "",
            "encryption": self.encryption ?? "",
        ]

        enableButton()
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
        conf?.serverAddress = "\(self.server ?? ""):\(self.port ?? "")"

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
                    print(error)
                    self.errorAlert(error)
                }

                return
            }

            // This is needed when storing for the first time, otherwise we will receive an error
            // "NEVPNErrorDomain Code=1".
            self.manager?.loadFromPreferences() { (error) -> Void in
                if let error = error {
                    print(error)
                    self.errorAlert(error)

                    return
                }

                do {
                    try self.session?.startVPNTunnel()
                } catch let error {
                    self.errorAlert(error)
                }

                self.commChannel()
            }
        }

//        let profile = profile_t()
//        start_ss_local_server(profile)

    }

    @objc func statusDidChange(_ note: Notification?) {
        let labelText: String
        let buttonText: String

        if let session = session {
            switch session.status {
            case .connecting:
                labelText = NSLocalizedString("connection establishing...", comment: "")
                buttonText = NSLocalizedString("Disconnect", comment: "")
            case .connected:
                labelText = NSLocalizedString("connection established", comment: "")
                buttonText = NSLocalizedString("Disconnect", comment: "")
            case .reasserting:
                labelText = NSLocalizedString("connection reestablishing...", comment: "")
                buttonText = NSLocalizedString("Disconnect", comment: "")
            case .disconnecting:
                labelText = NSLocalizedString("connection disestablishing...", comment: "")
                buttonText = NSLocalizedString("Connect", comment: "")
            case .invalid, .disconnected:
                labelText = NSLocalizedString("connection not established", comment: "")
                buttonText = NSLocalizedString("Connect", comment: "")
            }
        }
        else {
            labelText = NSLocalizedString("not initialized", comment: "")
            buttonText = NSLocalizedString("...waiting...", comment: "")
        }

        statusLb.text = labelText
        connectBt.setTitle(buttonText, for: UIControlState())
        enableButton()
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

        enableButton()
    }

    private func enableButton() {
        connectBt.isEnabled = !(server ?? "").isEmpty && !(port ?? "").isEmpty
            && !(password ?? "").isEmpty && !(encryption ?? "").isEmpty
    }

    private func errorAlert(_ error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                      message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    private func commChannel() {
        print("Attach to extension.")

        if session?.status != .invalid {
            do {
                try session?.sendProviderMessage(Data()) { response in
                    if let response = response {
                        if let response = NSKeyedUnarchiver.unarchiveObject(with: response) as? [String: Any] {
                            if let log = response["log"] as? [String] {
                                for line in log {
                                    print(line.trimmingCharacters(in: .whitespacesAndNewlines))
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Could not attach to extension. Error: \(error)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.commChannel)
        }
        else {
            print("Could not attach to extension. "
                + "VPN configuration does not exist or is not enabled. "
                + "No further actions will be taken.")
        }
    }
}
