//
//  ViewController.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/22/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var UsernameTextField: UITextField!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var test: UITextField!
    
    // MARK: UITextField Delegate
    
    // MARK: Actions
    
    /*
     Precondition: TextField Clicked (Touch Down)
     
     Postcondition: Clear Textfield
     */
    @IBAction func clearField(_ sender: UITextField) {
        UsernameTextField.text = ""; // Success
    } // Want to clear the text field when the user clicks on it. (Touch Down)
    
    // MARK: UIButton Delegate
    
    // MARK: Actions
    @IBAction func usernameInput(_ sender: Any) {
        test.text = UsernameTextField.text
    }
    
    /*
     Precondition: Button Clicked
     
     Postcondition:  Username shown in test textfield and transition to tableview
     */
    @IBAction func ClickChat(_ sender: Any) {
        if(UsernameTextField.text == "Enter a Username")
        {
            return // Not a proper username (should display a message)
        }
        
        // Not sure what to do for this
        
//        guard let username = UsernameTextField.text
//            else
//            {
//                print("Something went wrong")
//                return
//            }
//        test.text = username
        return
    }
    
    /*
     Precondition: App Initialized
     
     Postcondition: View loaded
     */

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        BLEServer.instance.delegate = self
        logTextView.text = ""
    }

    @IBAction func sendButtonTUI(_ sender: Any) {
        guard let data = messageTextField.text?.data(using: .ascii),
            let directPeer = BLEServer.instance.mostRecentPeer else {
                print("Either message couldn't be decoded or direct peer didn't exist")
                return
        }

        BLEServer.instance.send(data: data, to: directPeer)
    }
}

extension ViewController: BLEServerDelegate {
    
    func didReceivePacket(packet: Data) {
        let input = String(bytes: packet, encoding: .ascii) ?? "Oops, that didn't decode"
        self.logTextView.text += "\n \(input)"
    }
}




