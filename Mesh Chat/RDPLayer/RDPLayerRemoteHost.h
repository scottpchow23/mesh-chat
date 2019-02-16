//
//  RDPLayerRemoteHost.h
//  test-rdp
//
//  Created by CoolStar on 2/8/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDPPacket.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDPLayerRemoteHost : NSObject
@property (nonatomic, strong, readonly) NSUUID *peer;
@property (nonatomic, assign) uint32_t seqNum;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSMutableArray<RDPPacket *> *> *queuedPackets;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSMutableArray<RDPPacket *> *> *receivedPackets;
@property (nonatomic, strong, readonly) NSMutableArray *rawQueuedPackets;

- (instancetype)initWithPeer:(NSUUID *)uuid;
- (void)queuePacket:(RDPPacket *)packet;
- (void)startThread;
@end

NS_ASSUME_NONNULL_END
