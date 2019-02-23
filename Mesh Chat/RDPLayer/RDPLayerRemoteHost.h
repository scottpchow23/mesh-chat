//
//  RDPLayerRemoteHost.h
//  test-rdp
//
//  Created by CoolStar on 2/8/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDPPacket.h"

#define SLIDING_WINDOW_MIN 5
#define SLIDING_WINDOW_MAX 512
#define SLIDING_WINDOW_TIMEOUT 2

NS_ASSUME_NONNULL_BEGIN

@interface RDPLayerRemoteHost : NSObject
@property (nonatomic, strong, readonly) NSUUID *peer;
@property (nonatomic, assign) uint32_t seqNum;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSMutableArray<RDPPacket *> *> *queuedPackets;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSMutableArray<RDPPacket *> *> *receivedPackets;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, RDPPacket *> *lastAck;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSNumber *> *lastAckCount;
@property (nonatomic, strong, readonly) NSMutableArray *rawQueuedPackets;

- (instancetype)initWithPeer:(NSUUID *)uuid;
- (void)queuePacket:(RDPPacket *)packet;
- (void)startThread;

- (void)increaseSlidingWindow;
- (void)decreaseSlidingWindow;
- (void)resetSlidingWindow;
@end

NS_ASSUME_NONNULL_END
