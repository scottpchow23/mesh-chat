//
//  ChatViewController.swift
//  Mesh Chat
//
//  Created by Kevin Heffernan on 2/1/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {
    
    var messages: [MessageType] = []
    let thisUUID: String = (UserDefaults.standard.string(forKey: "theUUID")) ?? ""
    let thisUsername: String = (UserDefaults.standard.string(forKey: "theUsername")) ?? ""
    lazy var reciever = Sender(id: thisUUID, displayName: thisUsername)
    //lazy var sender = Sender(id: ,displayName: )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        
        messages.append(Message(sender: reciever, messageId: "1", sentDate: Date.distantFuture, text: "Hello"))
        messages.append(Message(sender: reciever, messageId: "2", sentDate: Date.distantFuture, text: "Here we are"))
        messages.append(Message(sender: reciever, messageId: "3", sentDate: Date.distantFuture, text: "Welcome to the future"))
        // Connect to a peripheral here
    }
    
    
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        // Looks like this should work
        return self.reciever
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        print(messages.count)
        return messages.count
    }
}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {}
