//
//  RDPLayer.h
//  test-rdp
//
//  Created by CoolStar on 2/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDPPacket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RDPLayerClientDelegate <NSObject>
- (void)receivedData:(NSData *)data fromUUID:(NSUUID *)uuid;
@end

@protocol RDPLayerDelegate <NSObject>
- (void)sendData:(NSData *)data toUUID:(NSUUID *)uuid;
@end

@interface RDPLayer : NSObject
@property (nonatomic, strong) NSObject<RDPLayerDelegate> *delegate;
@property (nonatomic, strong) NSObject<RDPLayerClientDelegate> *clientDelegate;

+ (instancetype)sharedInstance;
- (void)queueData:(NSData *)data toUUID:(NSUUID *)uuid;
- (void)didReceivePacket:(NSData * _Nonnull)data;
@end

NS_ASSUME_NONNULL_END
