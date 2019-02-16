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
#import "RDPLayer-Structs.h"

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
        assert(sizeof(struct linklayer_protocol_syn) == MTU);
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
    NSLog(@"Queuing data of length %d", data.length);
    
    RDPLayerRemoteHost *remoteHost = [_queuedPackets objectForKey:uuid];
    if (!remoteHost){
        remoteHost = [[RDPLayerRemoteHost alloc] initWithPeer:uuid];
        [_queuedPackets setObject:remoteHost forKey:uuid];
    }
    
    size_t len = data.length;
    uint32_t start = 0;
    while (len > 0){
        uint8_t packetLen = len;
        if (len > SYN_DATA_LEN)
            packetLen = SYN_DATA_LEN + 1;
        
        NSUUID *ourUUID = [[NSUUID alloc] initWithUUIDString:BLEServer.instance.rxUUID.UUIDString];
        
        struct linklayer_protocol_syn rawPacket;
        bzero(&rawPacket, sizeof(struct linklayer_protocol_syn));
        rawPacket.packet_type = LINKLAYER_PROTOCOL_PACKET_TYPE_SYN;
        rawPacket.seq_num = remoteHost.seqNum;
        rawPacket.start = start;
        rawPacket.len = packetLen;
        memcpy(rawPacket.data, data.bytes + start, MIN(packetLen, SYN_DATA_LEN));
        [ourUUID getUUIDBytes:rawPacket.uuid];
        uint32_t crc = 0;
        crc32(rawPacket.data, MIN(packetLen, SYN_DATA_LEN), &crc);
        rawPacket.crc32 = crc;
        
        RDPPacket *packet = [[RDPPacket alloc] initWithRawPacket:&rawPacket uuid:uuid];
        
        [remoteHost queuePacket:packet];
        
        start += MIN(packetLen, SYN_DATA_LEN);
        len -= MIN(packetLen, SYN_DATA_LEN);
    }
    
    [remoteHost startThread];
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
            if (!remoteHost){
                remoteHost = [[RDPLayerRemoteHost alloc] initWithPeer:uuid];
                [_queuedPackets setObject:remoteHost forKey:uuid];
            }
            NSMutableArray<RDPPacket *> *packets = [remoteHost.receivedPackets objectForKey:@(seqnum)];
            if (!packets){
                packets = [NSMutableArray array];
                [remoteHost.receivedPackets setObject:packets forKey:@(seqnum)];
            }
            [self sortPackets:packets];
            
            for (RDPPacket *packet in packets){
                if (packet.start == lenReceived){
                    lenReceived += packet.len;
                }
            }
            
            NSLog(@"Received seq for sequence number %d, length %d", seqnum, lenReceived);
            
            if (len < sizeof(struct linklayer_protocol_syncompact)){
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                //Send a NACK since we can here
                return;
            }
            if (len < sizeof(struct linklayer_protocol_syncompact) + MIN(synpacket->len, SYN_DATA_LEN)){
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                //Send a NACK since we didn't receive the full packet
                return;
            }
            
            int lenToUse = synpacket->len;
            if (lenToUse > SYN_DATA_LEN)
                lenToUse = SYN_DATA_LEN;
            
            uint32_t crc = 0;
            crc32(synpacket->data, lenToUse, &crc);
            if (crc != synpacket->crc32){
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                //Send a NACK since the data is corrupt
                return;
            } else {
                NSLog(@"Got Good Sequence Packet");
                
                //Packet is good, process it
                RDPPacket *packet = [[RDPPacket alloc] initWithRawPacket:synpacket uuid:uuid];
                if (packet.start < lenReceived){
                    NSLog(@"We already have this packet. Sending ack and ignoring.");
                    [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                    return;
                }
                
                [packets addObject:packet];
                [self sortPackets:packets];
                
                lenReceived = 0;
                for (RDPPacket *packet in packets){
                    if (packet.start == lenReceived){
                        lenReceived += packet.len;
                    }
                }
                
                if ([packets lastObject].isLastPacket && lenReceived == packets.lastObject.start+packets.lastObject.len){
                    NSLog(@"Got last packet!");
                    
                    uint8_t *data = malloc(sizeof(uint8_t) * lenReceived);
                    for (RDPPacket *packet in packets){
                        memcpy(data + packet.start, [packet.data bytes] + offsetof(struct linklayer_protocol_syn, data), packet.len);
                    }
                    
                    printf("Received: %s", data);
                    
                    NSData *receivedData = [NSData dataWithBytes:data length:lenReceived];
                    free(data);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.clientDelegate receivedData:receivedData fromUUID:uuid];
                    });
                }
                
                [self sendAck:seqnum receivedLen:lenReceived toUUID:uuid];
                return;
            }
            
            break;
        }
        case LINKLAYER_PROTOCOL_PACKET_TYPE_ACK: {
            struct linklayer_protocol_ack *ack = (struct linklayer_protocol_ack *)data;
            RDPLayerRemoteHost *remoteHost = [_queuedPackets objectForKey:uuid];
            NSMutableArray<RDPPacket *> *queuedPackets = [remoteHost.queuedPackets objectForKey:@(ack->ack_num)];
            
            NSLog(@"Received ack for sequence number %d, length %d", ack->ack_num, ack->len_received);
            
            NSMutableArray *idxToRemove = [NSMutableArray array];
            for (RDPPacket *packet in queuedPackets){
                if (packet.start + packet.len <= ack->len_received){
                    packet.acknowledged = YES;
                    NSLog(@"Marked packet for sequence number %d, start %d, length %d as acknowledged.", packet.seqNum, packet.start, packet.len);
                    [idxToRemove insertObject:@([queuedPackets indexOfObject:packet]) atIndex:0];
                }
            }
            
            for (NSNumber *idx in idxToRemove){
                [queuedPackets removeObjectAtIndex:idx.integerValue];
            }
            
            break;
        }
    }
}

- (void)sendAck:(uint32_t)seq_num receivedLen:(uint32_t)len toUUID:(NSUUID *)uuid {
    NSLog(@"Sent ack for sequence number %d, length %d", seq_num, len);
    
    NSUUID *ourUUID = [[NSUUID alloc] initWithUUIDString:BLEServer.instance.rxUUID.UUIDString];
    
    struct linklayer_protocol_ack ack;
    bzero(&ack, sizeof(struct linklayer_protocol_ack));
    ack.packet_type = LINKLAYER_PROTOCOL_PACKET_TYPE_ACK;
    ack.ack_num = seq_num;
    ack.len_received = len;
    [ourUUID getUUIDBytes:ack.uuid];
    
    RDPPacket *packet = [[RDPPacket alloc] initWithRawPacket:&ack uuid:uuid];
    
    [self sendPacket:packet];
}

- (void)sendPacket:(RDPPacket *)packet {
    int random = arc4random_uniform(10);
    if (random > 5){
        return;
    }
    
    packet.sent = YES;
    time_t now;
    time(&now);
    
    packet.sentTime = now;
    [_delegate sendData:packet.data toUUID:packet.peerUUID];
}

- (void)didReceivePacket:(NSData * _Nonnull)data {
    if (data.length < sizeof(struct linklayer_protocol_ack)){
        return;
    }
    struct linklayer_protocol_ack *ack = (struct linklayer_protocol_ack *)data.bytes;
    [self receivePacket:data fromUUID:[[NSUUID alloc] initWithUUIDBytes:ack->uuid]];
}

@end
