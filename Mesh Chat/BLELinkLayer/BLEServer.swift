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
    func didReceivePacket(_: Data, uuid: UUID)
}

protocol BLEDiscoverPeerDelegate {
    func didModifyPeerList()
}

@objc class BLEServer: NSObject {
    @objc static let instance = BLEServer()

    var delegate: BLEServerDelegate?
    var peerDelegate: BLEDiscoverPeerDelegate?
    let serviceUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27850"
    let txUUID = "4eb8b60f-a6c0-4681-b93a-4b29e3b27851"
    @objc var rxUUID = CBUUID(string: "4eb8b60f-a6c0-4681-b93a-4b29e3b27852") // DEFAULT VALUE
    let serviceName = "mesh_chat_dv"
    var txCharacteristic: CBCharacteristic?

    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var isAdvertising: Bool

    let thisUUID: String = (UserDefaults.standard.string(forKey: "theUUID")) ?? ""
    let thisUsername: String = (UserDefaults.standard.string(forKey: "theUsername")) ?? ""

    var directPeers: [DirectPeer] = [] {
        didSet {
            if let delegate = peerDelegate {
                delegate.didModifyPeerList()
            }
        }
    }

    var peripheralDict: [CBPeripheral: Bool] = [:]

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
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (service.characteristics?.count != 2) { return }
        var rxChar: CBCharacteristic?

        for characteristic in service.characteristics! {
            if (characteristic.uuid == CBUUID(string: txUUID)) {
                txCharacteristic = characteristic
            } else {
                rxChar = characteristic
            }
        }

        if let rxChar = rxChar {
            peripheral.readValue(for: rxChar)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value,
            let userAndId = try? JSONDecoder().decode(UserAndId.self, from: data),
            let txChar = txCharacteristic,
            let uuid = UUID(uuidString: userAndId.uuid) else {
            print("Couldn't gather all information needed for a direct peer")
            return
        }
        self.directPeers.append(DirectPeer(peripheral, uuid: uuid, name: userAndId.name, txCharacteristic: txChar))
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

                switch requests.first?.characteristic.uuid {
                case CBUUID(string: txUUID):
                    print("It's for the write characteristic")
                default:
                    print("Not sure what this packet was for")
                }

                let senderUUID = request.central.identifier
                RDPLayer.sharedInstance().didReceivePacket(data)
                if let delegate = self.delegate {
                    delegate.didReceivePacket(data, uuid: senderUUID)
                    for deleg in delegates {
                        deleg.didReceivePacket(data, uuid: senderUUID)
                    }
                }
            }
        }
    }

    struct UserAndId: Codable {
        var uuid: String
        var name: String
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == rxUUID {
            let userAndId = UserAndId(uuid: thisUUID, name: thisUsername)
            if let data = try? JSONEncoder().encode(userAndId) {
                request.value = data
                peripheralManager?.respond(to: request, withResult: .success)
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
        if let peer = directPeers.first(where: { $0.uuid == uuid}) {
            send(data: data, to: peer)
        }
    }
}
