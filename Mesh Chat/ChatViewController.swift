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

    var peer: DirectPeer?
    var messages: [MessageType] = []
    let thisUUID: String = (UserDefaults.standard.string(forKey: "theUUID")) ?? ""
    let thisUsername: String = (UserDefaults.standard.string(forKey: "theUsername")) ?? ""
    lazy var reciever = Sender(id: thisUUID, displayName: thisUsername)
    //lazy var sender = Sender(id: ,displayName: )
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.messageInputBar.delegate = self
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        RDPLayer.sharedInstance().clientDelegate = self
        
//        messages.append(Message(sender: reciever, messageId: "1", sentDate: Date.distantFuture, text: "Hello"))
//        messages.append(Message(sender: reciever, messageId: "2", sentDate: Date.distantFuture, text: "Here we are"))
//        messages.append(Message(sender: reciever, messageId: "3", sentDate: Date.distantFuture, text: "Welcome to the future"))
        // Connect to a peripheral here
    }


    
    
}

extension ChatViewController: RDPLayerClientDelegate {
    func receivedData(_ data: Data, from uuid: UUID) {
        if let codeableMessage = try? JSONDecoder().decode(CodableMessage.self, from: data) {
            let message = Message(codeableMessage)
            messages.append(message)
            messagesCollectionView.reloadData()
        } else {
            print("unable to decode message from data")
        }
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: thisUUID, displayName: thisUsername)
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
        let message = Message(sender: Sender(id: thisUUID, displayName: thisUsername), messageId: UUID().uuidString, sentDate: Date(), text: text)
        if let codableMessage = message.archive(),
            let peer = peer,
            let data = try? JSONEncoder().encode(codableMessage) {
            messages.append(message)
            messagesCollectionView.reloadData()
            inputBar.inputTextView.text = ""
            RDPLayer.sharedInstance().queue(data, to: peer.uuid)
        }
    }
}
