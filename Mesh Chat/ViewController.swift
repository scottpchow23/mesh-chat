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
    
    /*
     Precondition: Button Clicked
     
     Postcondition:  Username shown in test textfield and transition to tableview
     */
    @IBAction func ClickChat(_ sender: Any) {
        UsernameTextField.resignFirstResponder() // Hide the keyboard if the user has not already hit done
        guard let username = UsernameTextField.text
            else
            {
                print("Something went wrong")
                return
            }
        test.text = username
    }
    
    /*
     Precondition: App Initialized
     
     Postcondition: View loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

