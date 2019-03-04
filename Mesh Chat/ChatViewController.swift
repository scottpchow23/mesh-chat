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

    var peer: UserAndId?
    var messages: [MessageType] = []
    let thisUUID: String = (UserDefaults.standard.string(forKey: "theUUID")) ?? ""
    let thisUsername: String = (UserDefaults.standard.string(forKey: "theUsername")) ?? ""
    lazy var reciever = Sender(id: thisUUID, displayName: thisUsername)
    //lazy var sender = Sender(id: ,displayName: )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = thisUsername // Here we set the title for the chat
        self.title = peer?.name
        self.messageInputBar.delegate = self
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
//        RDPLayer.sharedInstance().clientDelegate = self
        P2PLayer.shared.delegate = self
    }


    
    
}

extension ChatViewController: P2PLayerDelegate {
    func didReceiveMessage(with data: Data, from uuid: UUID) {
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
        guard let peer = peer,
            let recipientUUID = UUID(uuidString: peer.uuid)  else {
            return
        }
        let message = Message(sender: Sender(id: thisUUID, displayName: thisUsername), messageId: UUID().uuidString, sentDate: Date(), text: text, recipient: recipientUUID)
        if let codableMessage = message.archive(),
            let data = try? JSONEncoder().encode(codableMessage) {
            messages.append(message)
            messagesCollectionView.reloadData()
            inputBar.inputTextView.text = ""
            P2PLayer.shared.sendNew(to: recipientUUID, message: data)
        }
    }
}
