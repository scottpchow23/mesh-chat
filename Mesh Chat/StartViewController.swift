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
    @IBOutlet weak var UsernameTextField: UITextField!
    
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
    
    @IBAction func clickedOutside(_ sender: Any) {
        print("test to see what runs first (this or readyToChat")
    }
    @IBAction func readyToChat(_ sender: Any) {
        let conversationListViewController = ConversationListViewController()
        self.navigationController?.pushViewController(conversationListViewController, animated: true)
    }
    

}



