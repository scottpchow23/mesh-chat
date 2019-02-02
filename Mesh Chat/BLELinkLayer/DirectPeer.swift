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
    var txCharacteristic: CBCharacteristic

    init(_ peripheral: CBPeripheral, txCharacteristic: CBCharacteristic) {
        self.peripheral = peripheral
        self.txCharacteristic = txCharacteristic
    }
}




