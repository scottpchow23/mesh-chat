//
//  BLEServer.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/24/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BLEServerDelegate {
    func didReceivePacket(packet: Data)
}

class BLEServer: NSObject {
    static let instance = BLEServer()



    var delegate: BLEServerDelegate?
    let meshChatDVUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27850"
    let writeDVUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27851"
    let readDVUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27852"
    let serviceDVName = "mesh_chat_dv"

    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var isAdvertising: Bool

    var peer: CBPeripheral?

    private override init() {
        isAdvertising = false
        super.init()
    }

    func startManagers() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

    }

    func send(message: String) {
        if let peer = peer {
//            if let data = message.data(using: .ascii) {
//
//                peer.writeValue(data, for: CBDescriptor( )
//            }
        } else {
            print("Unable to send message; no peer is present.")
        }
    }
}

extension BLEServer: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central is on!")
            centralManager?.scanForPeripherals(withServices: [CBUUID(string: meshChatDVUUID)], options: nil)
        default:
            print("Central is off.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Advertisement data: \n \n \(advertisementData)")
        if (advertisementData[CBAdvertisementDataLocalNameKey] as? String == serviceDVName &&
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? String == meshChatDVUUID) {
            print("Found peripheral advertising mesh service: \(String(describing: peripheral.name))")

            centralManager?.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: meshChatDVUUID)])
    }


}

extension BLEServer: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

    }
}

extension BLEServer: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral is on!")
            createServices()
            startAdvertising()
        default:
            print("Peripheral is off.")
        }
    }


    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            print("Peripheral started advertising!")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let data = requests.first?.value {
            let input = String(bytes: data, encoding: String.Encoding.ascii) ?? "Couldn't decode"
            print("Got a write request with input: \(input)")
            if let delegate = self.delegate {
                delegate.didReceivePacket(packet: data)
            }
        }
    }

    fileprivate func createServices() {
        let service = CBMutableService(type: CBUUID(string: meshChatDVUUID), primary: true)

        let writeCharacteristic = CBMutableCharacteristic(type: CBUUID(string: writeDVUUID), properties: [.write, .notify], value: nil, permissions: [.writeable])
        let readCharacteristic = CBMutableCharacteristic(type: CBUUID(string: readDVUUID), properties: [.read, .notify], value: nil, permissions: [.readable])

        service.characteristics = [writeCharacteristic, readCharacteristic]

        peripheralManager?.add(service)
    }

    func startAdvertising() {
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: meshChatDVUUID)],
                                             CBAdvertisementDataLocalNameKey: serviceDVName])
    }

    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
}
