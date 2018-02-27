//
//  PacketTunnelProvider.swift
//  extension
//
//  Created by Benjamin Erhart on 10.01.18.
//  Copyright © 2018 Guardian Project. All rights reserved.
//

import NetworkExtension
//import tun2socks

class PacketTunnelProvider: NEPacketTunnelProvider {

    private static let ENABLE_LOGGING = true
    private static var messageQueue: [String: Any] = ["log":[]]

    private var hostHandler: ((Data?) -> Void)?

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Add code here to start the process of connecting the tunnel.

        log("startTunnel, options: \(String(describing: options))")

        let profile = profile_t()
        start_ss_local_server(profile)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(nil)
        }

        while(true) {
            log("run")
            Darwin.sleep(1)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        log("stopTunnel, reason: \(reason)")

        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        log("handleAppMessage, messageData: \(messageData)")

        if PacketTunnelProvider.ENABLE_LOGGING {
            hostHandler = completionHandler
        }

    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }


    // MARK: Private

    private func sendMessages() {
        if PacketTunnelProvider.ENABLE_LOGGING, let handler = hostHandler {
            let response = NSKeyedArchiver.archivedData(withRootObject: PacketTunnelProvider.messageQueue)
            PacketTunnelProvider.messageQueue = ["log": []]
            handler(response)
            hostHandler = nil
        }
    }

    private func log(_ message: String) {
        PacketTunnelProvider.log(message)

        sendMessages()
    }

    private static func log(_ message: String) {
        if ENABLE_LOGGING, var log = messageQueue["log"] as? [String] {
            log.append("\(self): \(message)")
            messageQueue["log"] = log

            NSLog(message)
        }
    }
}
