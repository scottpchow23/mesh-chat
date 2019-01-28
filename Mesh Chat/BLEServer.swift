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
    let dvServiceUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27850"
    // Characteristic UUIDs
    let writeDVUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27851"
    let readDVUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27852"
    // Service Name
    let serviceDVName = "mesh_chat_dv"

    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var isAdvertising: Bool

    var peer: CBPeripheral?
    var writeDVCharacteristic: CBCharacteristic?

    private override init() {
        isAdvertising = false
        super.init()
    }

    func startManagers() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

    }

    func send(message: String) {
        guard let peer = peer,
            let data = message.data(using: .ascii),
            let txcharacteristic = writeDVCharacteristic else {
                return
        }

        peer.writeValue(data, for: txcharacteristic, type: .withoutResponse)
    }
}

extension BLEServer: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central is on!")
            centralManager?.scanForPeripherals(withServices: [CBUUID(string: dvServiceUUID)], options: nil)
        default:
            print("Central is off.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Advertisement data: \n \n \(advertisementData)")
        if (advertisementData[CBAdvertisementDataLocalNameKey] as? String == serviceDVName &&
            (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.first == CBUUID(string: dvServiceUUID)) {
            print("Found peripheral advertising mesh service: \(String(describing: peripheral.name))")
            peer = peripheral
            peer?.delegate = self
            centralManager?.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: dvServiceUUID)])
    }


}

extension BLEServer: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if (service.uuid == CBUUID(string: dvServiceUUID)) {
                peripheral.discoverCharacteristics([CBUUID(string: writeDVUUID), CBUUID(string: readDVUUID)], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if (characteristic.uuid == CBUUID(string: writeDVUUID)) {
                self.writeDVCharacteristic = characteristic
            } else if (characteristic.uuid == CBUUID(string: readDVUUID)) {

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
        if let data = requests.first?.value {
            let input = String(bytes: data, encoding: String.Encoding.ascii) ?? "Couldn't decode"
            print("Got a write request with input: \(input)")
            if let delegate = self.delegate {
                delegate.didReceivePacket(packet: data)
            }
        }
    }

    fileprivate func createServices() {
        let service = CBMutableService(type: CBUUID(string: dvServiceUUID), primary: true)

        let writeCharacteristic = CBMutableCharacteristic(type: CBUUID(string: writeDVUUID), properties: [.writeWithoutResponse], value: nil, permissions: [.writeable])
        let readCharacteristic = CBMutableCharacteristic(type: CBUUID(string: readDVUUID), properties: [.read, .notify], value: nil, permissions: [.readable])

        service.characteristics = [writeCharacteristic, readCharacteristic]

        peripheralManager?.add(service)
    }

    func startAdvertising() {
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: dvServiceUUID)],
                                             CBAdvertisementDataLocalNameKey: serviceDVName])
    }

    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
}
