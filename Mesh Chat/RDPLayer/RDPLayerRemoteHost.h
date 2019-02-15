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
@property (nonatomic, strong) NSUUID *peer;
@property (nonatomic, assign) uint32_t seqNum;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<RDPPacket *> *> *queuedPackets;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<RDPPacket *> *> *receivedPackets;
@property (nonatomic, assign) pthread_mutex_t threadLock;
@property (nonatomic, assign) bool threadIsRunning;
@property (nonatomic, assign) pthread_t thread;
@end

NS_ASSUME_NONNULL_END
