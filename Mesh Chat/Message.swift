//
//  Message.swift
//  Mesh Chat
//
//  Created by Kevin Heffernan on 2/1/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import Foundation
import MessageKit

struct Message : MessageType{
    var sender: Sender
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    init(sender: Sender, messageId : String, sentDate : Date, text : String) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = .text(text)
    }
    
    
}
