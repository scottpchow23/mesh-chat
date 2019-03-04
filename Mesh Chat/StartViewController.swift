//
//  ViewController.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/22/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    // MARK: Properties
    var firstTouch: Bool = true
    
    var username: String = UserDefaults.standard.string(forKey: "theUsername") ?? "Enter a Username"
    
    @IBOutlet weak var UsernameTextField: UITextField!
    @IBOutlet weak var chatButton: UIButton!
    
    
    // How do we store the username?
    
    // MARK: Actions
    
    override func viewDidLoad() {
        UsernameTextField.text = username
        self.title = "Login"
    }
    /*
     Precondition: TextField Clicked (Touch Down)
     
     Postcondition: Clear Textfield
     */
    @IBAction func clearField(_ sender: UITextField) {
        if(firstTouch){
            UsernameTextField.text = ""; // Success
        }
        firstTouch = false
    } // Want to clear the text field when the user clicks on it. (Touch Down)
    
   
    @IBAction func dismissKeyBoard(_ sender: UITextField) {
        self.resignFirstResponder()
    }
    @IBAction func didEndOnExit(_ sender: Any) {
        print("Triggered")
    }
    @IBAction func usernameValueChanged(_ sender: Any) {
        print("Triggered")
    }
    
    @IBAction func readyToChat(_ sender: UIButton) {
        
        
        if(UsernameTextField.text == "" || UsernameTextField.text == "Enter a Username"){
            return
        }
        else{
            username = UsernameTextField.text ?? ""
            if(username == ""){
                return // do not allow navagation without a username
            }
            else{
                // Set a uuid for the user
                let uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: "theUUID") // Assign UUID to user defaults
                // Also store the username
                UserDefaults.standard.set(username, forKey: "theUsername")
            }
        }
        
        let conversationListViewController = ConversationListViewController()
        
            conversationListViewController.user = username
        self.navigationController?.pushViewController(conversationListViewController, animated: true)
    }
    

}



