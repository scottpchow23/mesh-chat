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
    var username: String = ""
    @IBOutlet weak var UsernameTextField: UITextField!
    @IBOutlet weak var chatButton: UIButton!
    
    
    // MARK: Actions
    
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
                // Generate unique UUID
            }
        }
        let conversationListViewController = ConversationListViewController(username)
        self.navigationController?.pushViewController(conversationListViewController, animated: true)
    }
    

}



