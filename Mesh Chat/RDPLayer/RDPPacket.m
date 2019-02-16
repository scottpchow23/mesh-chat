//
//  RDPPacket.m
//  test-rdp
//
//  Created by CoolStar on 2/8/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import "RDPPacket.h"
#import "RDPLayer-Structs.h"

@implementation RDPPacket
- (instancetype)initWithRawPacket:(struct linklayer_protocol_syn *)syn uuid:(NSUUID *)uuid {
    self = [super init];
    if (self){
        self.sent = NO;
        self.acknowledged = NO;
        self.sentTime = 0;
        self.didNotReceiveCount = 0;
        
        if (syn->packet_type == LINKLAYER_PROTOCOL_PACKET_TYPE_SYN){
            self.seqNum = syn->seq_num;
            self.start = syn->start;
            self.len = syn->len;
            self.peerUUID = uuid;
            self.data = [NSData dataWithBytes:syn length:sizeof(struct linklayer_protocol_syn)];
        } else if (syn->packet_type == LINKLAYER_PROTOCOL_PACKET_TYPE_ACK){
            struct linklayer_protocol_ack *ack = syn;
            self.seqNum = ack->ack_num;
            self.peerUUID = uuid;
            self.data = [NSData dataWithBytes:ack length:sizeof(struct linklayer_protocol_ack)];
        }
    }
    return self;
}
@end
