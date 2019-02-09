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
    let scott = Sender(id: "123", displayName: "Scott")
    let prabal = Sender(id: "456", displayName: "Prabal")
    let kevin = Sender(id: "789", displayName: "Kevin")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.messageInputBar.delegate = self
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messages.append(Message(sender: scott, messageId: "1", sentDate: Date.distantFuture, text: "Hello"))
        messages.append(Message(sender: prabal, messageId: "2", sentDate: Date.distantFuture, text: "Here we are"))
        messages.append(Message(sender: kevin, messageId: "3", sentDate: Date.distantFuture, text: "Welcome to the future"))
        // Connect to a peripheral here
    }


    
    
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        let scott = Sender(id: "123", displayName: "Scott")

        
        return scott
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

extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        if let peer = BLEServer.instance.mostRecentPeer, let data = text.data(using: .ascii) {
            RDPLayer.sharedInstance().queue(data, to: peer.uuid)
        }
    }
}
