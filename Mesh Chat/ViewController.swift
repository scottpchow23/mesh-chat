//
//  ViewController.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/22/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // Mark: Properties
    
    @IBOutlet weak var UsernameTextField: UITextField!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var test: UITextField!
    
    /*
     Precondition: Button Clicked
     
     Postcondition:  Username shown in test textfield and transition to tableview
     */
    @IBAction func clearField(_ sender: UITextField) {
        UsernameTextField.text = ""; // Success
    } // Want to clear the text field when the user clicks on it. (Touch Down)
    
    /*
     Precondition: Button Clicked
     
     Postcondition:  Username shown in test textfield and transition to tableview
     */
    @IBAction func ClickChat(_ sender: Any) {
        guard let username = UsernameTextField.text
            else
            {
                print("Something went wrong")
                return
            }
        test.text = username
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

