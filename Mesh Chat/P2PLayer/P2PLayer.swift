//
//  P2PLayer.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 3/1/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import Foundation

typealias DV = [UserAndId: (Int, UserAndId)]

struct UserAndId: Codable, Hashable {
    var uuid: String
    var name: String
}

class DistanceVector: Codable {
    var nextHopVector: [UserAndId: UserAndId] = [:]
    var distanceVector: [UserAndId: Int] = [:]
    var owner: UserAndId



    init(with user: UserAndId) {
        nextHopVector[user] = user
        distanceVector[user] = 0
        owner = user
    }

    func peers() -> [UserAndId] {
        let fullPeerList = Array(nextHopVector.keys)
        return fullPeerList.filter {$0.uuid != owner.uuid }
    }

    func update(with vector: DistanceVector) {
        for (remotePeer, hops) in vector.distanceVector {
            if nextHopVector[remotePeer] == nil {
                print("Adding new peer: \(remotePeer.name)")
                addPeer(remote: remotePeer, hops: hops + 1, next: vector.owner)
            } else if let currentHops = distanceVector[remotePeer], currentHops > hops + 1 {
                print("Updating path to peer: \(remotePeer.name), \(currentHops) -> \(hops + 1)")
                addPeer(remote: remotePeer, hops: hops + 1, next: vector.owner)
            }
        }
    }

    func addPeer(remote: UserAndId, hops: Int, next: UserAndId) {
        nextHopVector[remote] = next
        distanceVector[remote] = hops
    }

    func zipped() -> DV {
        var dict = DV()
        for (key, nextHop) in nextHopVector {
            if let distance = distanceVector[key] {
                dict[key] = (distance, nextHop)
            }
        }
        if dict.keys.count != nextHopVector.keys.count {
            fatalError("failed to zip DV")
        }
        return dict
    }

    func filter()
}


protocol P2PLayerDelegate {
    func didReceiveMessage(with data: Data, from uuid: UUID)
}

protocol P2PPeerDelegate {
    func didModifyPeerList()
}

class P2PLayer: NSObject {
    static let shared = P2PLayer()

    let thisUUID: String = (UserDefaults.standard.string(forKey: "theUUID")) ?? ""
    let thisUsername: String = (UserDefaults.standard.string(forKey: "theUsername")) ?? ""
    var distanceVector: DistanceVector
    var delegate: P2PLayerDelegate?
    var peerDelegate: P2PPeerDelegate?

    override init() {
        distanceVector = DistanceVector(with: UserAndId(uuid: thisUUID, name: thisUsername))
        super.init()
        RDPLayer.sharedInstance().clientDelegate = self
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (_) in
            self.broadcastDV()
        }
    }

    func nextHop(for uuid: UUID) -> UserAndId? {
        if let endGoal = distanceVector.nextHopVector.keys.first(where: { (user) -> Bool in
            return user.uuid == uuid.uuidString
        }) {
            return distanceVector.nextHopVector[endGoal]
        }
        return nil
    }

    func sendNew(to peer: UUID, message: Data) {
        var newData = Data()
        let type: UInt8 = 0
        newData.append(type)
        newData.append(message)
        send(to: peer, data: newData)
    }

    func send(to peer:UUID, data: Data) {
        if let nextHop = nextHop(for: peer) {
            RDPLayer.sharedInstance().queue(data, to: peer)
        } else {
            print("Failed to find next hop to: \(peer.uuidString)")
        }
    }

    @objc func broadcastDV() {
        print("Broadcasting!")
        let directPeers = BLEServer.instance.directPeers
        guard let distanceVectorData = try? JSONEncoder.init().encode(distanceVector) else {
            print("Failed to encode distance vector")
            return
        }
        var newData = Data()
        let type: UInt8 = 1
        newData.append(type)
        newData.append(distanceVectorData)
        for peer in directPeers {
            RDPLayer.sharedInstance().queue(newData, to: peer.uuid)
        }
    }

}

extension P2PLayer: BLEDiscoverPeerDelegate {
    func didModifyPeerList() {
//        let directPeers = BLEServer.instance.directPeers
//        distanceVector.nextHopVector = distanceVector.nextHopVector.filter { (tuple) -> Bool in
//            return directPeers.contains {$0.uuid.uuidString == tuple.key.uuid}
//        }
//
//        distanceVector.distanceVector = distanceVector.distanceVector.filter{ (tuple) -> Bool in
//            return directPeers.contains {$0.uuid.uuidString == tuple.key.uuid}
//        }
    }
}

extension P2PLayer: RDPLayerClientDelegate {
    func receivedData(_ data: Data, from uuid: UUID) {
        if let type = data.first{
            switch type {
            case 0:
                print("Received message")
                let messageData = data.dropFirst()
                if let message = try? JSONDecoder.init().decode(CodableMessage.self, from: messageData) {
                    if message.recipient.uuidString == thisUUID {
                        // Message is for us
                        if let delegate = delegate {
                            delegate.didReceiveMessage(with: messageData, from: uuid)
                        }
                    } else {
                        // Message needs to be forwarded
                        send(to: message.recipient, data: data)
                    }
                } else {
                    print("Failed to decode message; make sure you didn't strip an important byte")
                }

            case 1:
                print("Received distance vector")
                let distanceVectorData = data.dropFirst()
                guard let distanceVector = try? JSONDecoder.init().decode(DistanceVector.self, from: distanceVectorData) else  {
                    print("failed to decode distance vector")
                    return
                }

                self.distanceVector.update(with: distanceVector)
                self.peerDelegate?.didModifyPeerList()
            default:
                print("This is not a type of P2P message we recognize")
            }
        }
    }
}
