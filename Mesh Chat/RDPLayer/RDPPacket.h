//
//  RDPPacket.h
//  test-rdp
//
//  Created by CoolStar on 2/8/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDPPacket : NSObject
@property (nonatomic, assign) uint32_t seqNum;
@property (nonatomic, assign) uint32_t start;
@property (nonatomic, assign) uint32_t len;
@property (nonatomic, retain) NSUUID *peerUUID;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, assign) BOOL sent;
@property (nonatomic, assign) time_t sentTime;
@property (nonatomic, assign) BOOL acknowledged;

- (instancetype)initWithRawPacket:(struct linklayer_protocol_syn *)syn;
@end

NS_ASSUME_NONNULL_END
