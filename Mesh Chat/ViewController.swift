//
//  ViewController.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/22/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        BLEServer.instance.delegate = self
        logTextView.text = ""
    }

    @IBAction func sendButtonTUI(_ sender: Any) {
        if let message = messageTextField.text {
            BLEServer.instance.send(message: message)
        }
    }
}

extension ViewController: BLEServerDelegate {
    
    func didReceivePacket(packet: Data) {
        let input = String(bytes: packet, encoding: .ascii) ?? "Oops, that didn't decode"
        self.logTextView.text += "\n \(input)"
    }
}




