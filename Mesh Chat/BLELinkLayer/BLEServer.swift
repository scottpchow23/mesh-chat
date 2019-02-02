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
    // Service UUID
    let serviceUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27850"
    // Characteristic UUIDs
    let txUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27851"
    // Service Name
    let serviceName = "mesh_chat_dv"

    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var isAdvertising: Bool

    var writeDVCharacteristics: [CBCharacteristic] = []
    var peripheralDict: [CBPeripheral: Bool] = [:]
    var mostRecentPeer: DirectPeer?
    var directPeers: [DirectPeer] = []
    var delegates: [BLEServerDelegate] = []

    private override init() {
        isAdvertising = false
        super.init()
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
            peripheralDict[peripheral] = false
            peripheral.delegate = self
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                print("Connecting to \(peripheral.identifier)")
                self.centralManager?.connect(peripheral, options: nil)
            }
        }

    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: serviceUUID)])
        peripheralDict[peripheral] = true
        for (peripheral, didConnect) in peripheralDict {
            if (!didConnect) {
                centralManager?.connect(peripheral, options: nil)
                break
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        directPeers.removeAll { (peer) -> Bool in
            print("Peripheral \(peripheral.identifier) disconnected.")
            return peer.peripheral.identifier == peripheral.identifier
        }
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: serviceUUID)], options: nil)
    }


}

extension BLEServer: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if (service.uuid == CBUUID(string: serviceUUID)) {
                peripheral.discoverCharacteristics([CBUUID(string: txUUID)], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var char: CBCharacteristic?
        for characteristic in service.characteristics! {
            if (characteristic.uuid == CBUUID(string: txUUID)) {
                char = characteristic
            }
        }
        guard let txCharacteristic = char else {
            print("Didn't discover all required characteristics on the peripheral's mesh service")
            return
        }
        self.mostRecentPeer = DirectPeer(peripheral, txCharacteristic: txCharacteristic)
        self.directPeers.append(DirectPeer(peripheral, txCharacteristic: txCharacteristic))
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        let serviceInvalid = invalidatedServices.contains { (service) -> Bool in
            return service.uuid.uuidString == serviceUUID
        }
        if (serviceInvalid) {
            directPeers.removeAll { (peer) -> Bool in
                return peer.peripheral.identifier == peripheral.identifier
            }
        }
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

                if let delegate = self.delegate {
                    delegate.didReceivePacket(packet: data)
                    for deleg in delegates {
                        deleg.didReceivePacket(packet: data)
                    }
                }
            }
        }


    }

    fileprivate func createServices() {
        let service = CBMutableService(type: CBUUID(string: serviceUUID), primary: true)

        let txCharacteristic = CBMutableCharacteristic(type: CBUUID(string: txUUID), properties: [.writeWithoutResponse], value: nil, permissions: [.writeable])

        service.characteristics = [txCharacteristic]

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
