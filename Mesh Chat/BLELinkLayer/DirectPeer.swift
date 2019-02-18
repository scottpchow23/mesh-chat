//
//  DirectPeer.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/28/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import Foundation
import CoreBluetooth

struct DirectPeer {

    var peripheral: CBPeripheral
    var uuid: UUID
    var name: String
    var txCharacteristic: CBCharacteristic

    init(_ peripheral: CBPeripheral, uuid: UUID, name: String, txCharacteristic: CBCharacteristic) {
        self.peripheral = peripheral
        self.uuid = uuid
        self.name = name
        self.txCharacteristic = txCharacteristic
    }
}




