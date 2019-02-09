//
//  BLEServer.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/24/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import Foundation
import CoreBluetooth


@objc protocol BLEServerDelegate {
    func didReceivePacket(_ : Data, uuid: UUID)
}

class BLEServer: NSObject {
    static let instance = BLEServer()



    var delegate: BLEServerDelegate?
    // Service UUID
    let serviceUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27850"
    // Characteristic UUIDs
    let txUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27851"
    var rxUUID = CBUUID(string: "4eb8b60f-a6c0-4681-b93a-4b29e3b27852") // DEFAULT VALUE
    // Service Name
    let serviceName = "mesh_chat_dv"

    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var isAdvertising: Bool

    var writeDVCharacteristics: [CBCharacteristic] = []
    var peer: CBPeripheral?
    var txCharacteristic: CBCharacteristic?
    var mostRecentPeer: DirectPeer?
    var directPeers: [DirectPeer] = []
    var delegates: [BLEServerDelegate] = []

    private override init() {
        isAdvertising = false
        super.init()
        RDPLayer.sharedInstance().delegate = self
    }

    func startManagers() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

    }

    func send(data: Data, to peer: DirectPeer) {
        peer.peripheral.writeValue(data, for: peer.txCharacteristic, type: .withoutResponse)
    }
}

extension BLEServer: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central is on!")
            centralManager?.scanForPeripherals(withServices: [CBUUID(string: serviceUUID)], options: nil)
        default:
            print("Central is off.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Advertisement data: \n \n \(advertisementData)")
        if (advertisementData[CBAdvertisementDataLocalNameKey] as? String == serviceName &&
            (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.first == CBUUID(string: serviceUUID)) {
            print("Found peripheral advertising mesh service: \(String(describing: peripheral.name))")
            peer = peripheral
            peer?.delegate = self
            centralManager?.connect(peripheral, options: nil)
        }

    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: serviceUUID)])
    }


}

extension BLEServer: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if (service.uuid == CBUUID(string: serviceUUID)) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (service.characteristics?.count != 2) { return }

        var string: String?

        for characteristic in service.characteristics! {
            if (characteristic.uuid == CBUUID(string: txUUID)) {
                self.txCharacteristic = characteristic

            } else {
                print ("We got: \(characteristic.uuid.uuidString)")
                string = characteristic.uuid.uuidString
            }
        }
        guard let txCharacteristic = txCharacteristic,
            let uuidString = string,
            let uuid = UUID(uuidString: uuidString) else {
            print("Didn't discover all required characteristics on the peripheral's mesh service")
            return
        }


        self.mostRecentPeer = DirectPeer(peripheral, uuid: uuid, txCharacteristic: txCharacteristic)
        self.directPeers.append(DirectPeer(peripheral, uuid: uuid, txCharacteristic: txCharacteristic))
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
        for request in requests {
            if let data = request.value {
                let input = String(bytes: data, encoding: String.Encoding.ascii) ?? "Couldn't decode"
                print("Got a write request with input: \(input)")

                switch requests.first?.characteristic.uuid {
                case CBUUID(string: txUUID):
                    print("It's for the write characteristic")
                default:
                    print("Not sure what this packet was for")
                }
                let senderUUID = request.central.identifier
                if let delegate = self.delegate {
                    delegate.didReceivePacket(data, uuid: senderUUID)
                    for deleg in delegates {
                        deleg.didReceivePacket(data, uuid: senderUUID)
                    }
                }
            }
        }


    }

    fileprivate func createServices() {
        let service = CBMutableService(type: CBUUID(string: serviceUUID), primary: true)

        let txCharacteristic = CBMutableCharacteristic(type: CBUUID(string: txUUID), properties: [.writeWithoutResponse], value: nil, permissions: [.writeable])
        let rxCharacteristic = CBMutableCharacteristic(type: rxUUID, properties: [.read], value: nil, permissions: [.readable])
        service.characteristics = [txCharacteristic, rxCharacteristic]

        peripheralManager?.add(service)
    }

    func startAdvertising() {
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: serviceUUID)],
                                             CBAdvertisementDataLocalNameKey: serviceName])
    }

    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
}

extension BLEServer: RDPLayerDelegate {
    func send(_ data: Data, to uuid: UUID) {
        if let peer = directPeers.first(where: { $0.peripheral.identifier == uuid}) {
            send(data: data, to: peer)
        }
    }
}
