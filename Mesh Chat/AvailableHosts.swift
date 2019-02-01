//
//  AvailableHosts.swift
//  Mesh Chat
//
//  Created by Kevin Heffernan on 1/31/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit

class AvailableHosts: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // One Section that contains the number of rows returned in tableView function below
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // One row in each section
        return 2
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)

        // Configure the cell...
        // Lines 41 - 54 are MVP
        if(indexPath.row == 0)
        {
            // Show first default message
            cell.textLabel?.text = "Chat with Scott" // finish this
            
        }
        else if(indexPath.row == 1)
        {
            // Show second default message
            cell.textLabel?.text = "Chat with Prabal" // finish this
        }
        else{
            cell.textLabel?.text = "Section \(indexPath.section) Row \(indexPath.row)"}

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Messages" // Eventually we'll want to do Unread vs Read
        // or Favorites or something of the like
    }


}
