//
//  Message.swift
//  Mesh Chat
//
//  Created by Kevin Heffernan on 2/1/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import Foundation
import MessageKit

struct CodableMessage: Codable {
    var senderID: String
    var senderName: String
    var messageID: String
    var sentDate: Date
    var text: String
    var recipient: UUID
}

struct Message : MessageType{

    var sender: Sender
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var recipient: UUID
    
    init(sender: Sender, messageId : String, sentDate : Date, text : String, recipient: UUID) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = .text(text)
        self.recipient = recipient
    }

    init(_ codeable: CodableMessage) {
        sender = Sender(id: codeable.senderID, displayName: codeable.senderName)
        messageId = codeable.messageID
        sentDate = codeable.sentDate
        kind = .text(codeable.text)
        recipient = codeable.recipient
    }

    func archive() -> CodableMessage? {
        switch kind {
        case let .text(string):
            return CodableMessage(senderID: sender.id, senderName: sender.displayName, messageID: messageId, sentDate: sentDate, text: string, recipient: recipient)
        default:
            return nil
        }

    }
    
}

// Below is an example of how to both encode and decode a message

//    let message = Message(sender: Sender(id: "456", displayName: "Scott") , messageId: "123", sentDate: Date(), text: "Hello World")
//    if let archive = message.archive() {
//        let jsonEncoder = JSONEncoder()
//        if let jsonData = try? jsonEncoder.encode(archive) {
//            if let decodedMessage = try? JSONDecoder().decode(CodableMessage.self, from: jsonData) {
//                let unarchivedMessage = Message(decodedMessage)
//                print(unarchivedMessage)
//            }
//        } else {
//
//        }
//    } else {
//        fatalError("Couldn't archive message")
//    }
