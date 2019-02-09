//
//  RDPLayer.m
//  test-rdp
//
//  Created by CoolStar on 2/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import "RDPLayer.h"
#import "RDPLayerRemoteHost.h"
#import "crc32_simple.h"
#import "Mesh_Chat-Swift.h"

enum LINKLAYER_PROTOCOL_PACKET_TYPE {
    LINKLAYER_PROTOCOL_PACKET_TYPE_SYN,
    LINKLAYER_PROTOCOL_PACKET_TYPE_ACK
};

struct linklayer_protocol_syncompact {
    uint8_t packet_type;
    uint32_t seq_num;
    uint8_t ttl;
    uint32_t start;
    uint8_t len; //if this is less than or equal to 171, this is the last packet
    uint32_t crc32;
} __attribute__((packed));

struct linklayer_protocol_syn {
    uint8_t packet_type;
    uint32_t seq_num;
    uint8_t ttl;
    uint32_t start;
    uint8_t len; //if this is less than or equal to 171, this is the last packet
    uint32_t crc32;
    char data[170];
} __attribute__((packed));

struct linklayer_protocol_ack {
    uint8_t packet_type;
    uint32_t ack_num;
    uint32_t len_received;
} __attribute__((packed));

@interface RDPLayer () <BLEServerDelegate>{
    NSMutableDictionary<NSUUID *, RDPLayerRemoteHost *> *_queuedPackets;
    NSMutableDictionary<NSUUID *, RDPLayerRemoteHost *> *_receivedPackets;
}
@end

@implementation RDPLayer
+ (instancetype)sharedInstance
{
    static RDPLayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RDPLayer alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self){
        _queuedPackets = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)queueData:(NSData *)data toUUID:(NSUUID *)uuid {
    RDPLayerRemoteHost *remoteHost = [_queuedPackets objectForKey:uuid];
    if (!remoteHost){
        remoteHost = [[RDPLayerRemoteHost alloc] init];
        remoteHost.peer = uuid;
        remoteHost.seqNum = 0;
        remoteHost.queuedPackets = [NSMutableDictionary dictionary];
        remoteHost.receivedPackets = [NSMutableDictionary dictionary];
        [_queuedPackets setObject:remoteHost forKey:uuid];
    }
    
    size_t len = data.length;
    uint32_t start = 0;
    while (len > 0){
        uint8_t packetLen = len;
        if (len > 170)
            packetLen = 170;
        
        struct linklayer_protocol_syn rawPacket;
        bzero(&rawPacket, sizeof(struct linklayer_protocol_syn));
        rawPacket.packet_type = LINKLAYER_PROTOCOL_PACKET_TYPE_SYN;
        rawPacket.seq_num = remoteHost.seqNum;
        rawPacket.start = start;
        rawPacket.len = packetLen;
        memcpy(rawPacket.data, data.bytes + start, packetLen);
        uint32_t crc;
        crc32(rawPacket.data, packetLen, &crc);
        rawPacket.crc32 = crc;
        
        RDPPacket *packet = [[RDPPacket alloc] init];
        packet.seqNum = rawPacket.seq_num;
        packet.start = start;
        packet.len = packetLen;
        packet.peerUUID = uuid;
        packet.data = [NSData dataWithBytes:(void *)&rawPacket length:sizeof(struct linklayer_protocol_syn)];
        
        NSMutableArray *queueArray = [remoteHost.queuedPackets objectForKey:@(packet.seqNum)];
        if (!queueArray){
            queueArray = [NSMutableArray array];
            [remoteHost.queuedPackets setObject:queueArray forKey:@(packet.seqNum)];
        }
        [queueArray addObject:packet];
        [self sortPackets:queueArray];
        
        start += packetLen;
        len -= packetLen;
    }
    
    for (RDPPacket *packet in remoteHost.queuedPackets[@(remoteHost.seqNum)]){
        [self sendPacket:packet];
    }
    remoteHost.seqNum++;
}

- (void)sortPackets:(NSMutableArray *)packets {
    [packets sortUsingComparator:^NSComparisonResult(RDPPacket *_Nonnull obj1, RDPPacket *_Nonnull obj2) {
        if (obj1.start < obj2.start){
            return NSOrderedAscending;
        } else if (obj1.start > obj2.start){
            return NSOrderedDescending;
        } else {
            @throw [NSException exceptionWithName:@"RDPLayerException" reason:@"Multiple packets have the same sequence number and start byte." userInfo:nil];
        }
    }];
}

- (void)receivePacket:(NSData *)rawPacket fromUUID:(NSUUID *)uuid {
    uint8_t *data = (uint8_t *)rawPacket.bytes;
    uint32_t len = (uint32_t)rawPacket.length;
    
    if (len < sizeof(struct linklayer_protocol_ack)){
        return; //Size of data is smaller than our smallest packet
    }
    
    switch (data[0]){
        case LINKLAYER_PROTOCOL_PACKET_TYPE_SYN: {
            struct linklayer_protocol_syn *synpacket = (struct linklayer_protocol_syn *)data;
            uint32_t seqnum = synpacket->seq_num;
            
            uint32_t lenReceived = 0;
            
            RDPLayerRemoteHost *remoteHost = [_queuedPackets objectForKey:uuid];
            NSMutableArray<RDPPacket *> *packets = [remoteHost.receivedPackets objectForKey:@(seqnum)];
            [self sortPackets:packets];
            
            for (RDPPacket *packet in packets){
                if (packet.start == lenReceived){
                    lenReceived += packet.len;
                }
            }
            
            if (len < sizeof(struct linklayer_protocol_syncompact)){
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                //Send a NACK since we can here
                return;
            }
            if (len < sizeof(struct linklayer_protocol_syncompact) + synpacket->len){
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                //Send a NACK since we didn't receive the full packet
                return;
            }
            uint32_t crc;
            crc32(synpacket->data, synpacket->len, &crc);
            if (crc != synpacket->crc32){
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                //Send a NACK since the data is corrupt
                return;
            } else {
                //Packet is good, process it
                RDPPacket *packet = [[RDPPacket alloc] init];
                packet.peerUUID = uuid;
                packet.seqNum = seqnum;
                packet.start = synpacket->start;
                packet.len = synpacket->len;
                packet.data = rawPacket;
                [packets addObject:packet];
                [self sortPackets:packets];
                
                lenReceived = 0;
                for (RDPPacket *packet in packets){
                    if (packet.start == lenReceived){
                        lenReceived += packet.len;
                    }
                }
                
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                return;
            }
            
            break;
        }
        case LINKLAYER_PROTOCOL_PACKET_TYPE_ACK: {
            struct linklayer_protocol_ack *synpacket = (struct linklayer_protocol_ack *)data;
            RDPLayerRemoteHost *remoteHost = [_queuedPackets objectForKey:uuid];
            NSArray *queuedPackets = [remoteHost.queuedPackets objectForKey:@(synpacket->ack_num)];
            
            
            
            break;
        }
    }
}

- (void)sendAck:(uint32_t)seq_num receivedLen:(uint32_t)len toUUID:(NSUUID *)uuid {
    struct linklayer_protocol_ack ack;
    bzero(&ack, sizeof(struct linklayer_protocol_ack));
    ack.packet_type = LINKLAYER_PROTOCOL_PACKET_TYPE_ACK;
    ack.ack_num = seq_num;
    ack.len_received = len;
    
    RDPPacket *packet = [[RDPPacket alloc] init];
    packet.seqNum = ack.ack_num;
    packet.peerUUID = uuid;
    packet.data = [NSData dataWithBytes:&ack length:sizeof(struct linklayer_protocol_ack)];
    
    [self sendPacket:packet];
}

- (void)sendPacket:(RDPPacket *)packet {
    [_delegate sendData:packet.data toUUID:packet.peerUUID];
}



- (void)didReceivePacket:(NSData * _Nonnull)_ {
    
}

@end
