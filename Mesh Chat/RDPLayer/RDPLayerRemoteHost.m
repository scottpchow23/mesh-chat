//
//  RDPLayerRemoteHost.m
//  test-rdp
//
//  Created by CoolStar on 2/8/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import "RDPLayerRemoteHost.h"
#import "RDPLayer.h"
#import <pthread.h>

#define SLIDING_WINDOW 3

@interface RDPLayerRemoteHost() {
    pthread_mutex_t _lock;
    pthread_mutex_t _threadLock;
    pthread_t _thread;
    bool _threadIsRunning;
}

- (void)runThread;
@end

@interface RDPLayer ()
- (void)sendPacket:(RDPPacket *)packet;
@end

void *remoteHostThread(RDPLayerRemoteHost *self){
    [self runThread];
    return NULL;
}

@implementation RDPLayerRemoteHost
- (instancetype)initWithPeer:(NSUUID *)uuid {
    self = [super init];
    if (self){
        self->_peer = uuid;
        self->_seqNum = 0;
        self->_queuedPackets = [NSMutableDictionary dictionary];
        self->_receivedPackets = [NSMutableDictionary dictionary];
        self->_rawQueuedPackets = [NSMutableArray array];
        
        self->_threadIsRunning = false;
        pthread_mutex_init(&self->_lock, NULL);
        pthread_mutex_init(&self->_threadLock, NULL);
    }
    return self;
}

- (void)startThread {
    if (self->_threadIsRunning){
        return;
    }
    pthread_mutex_lock(&self->_threadLock);
    if (self->_threadIsRunning){
        pthread_mutex_unlock(&self->_threadLock);
        return;
    }
    pthread_mutex_unlock(&self->_threadLock);
    pthread_mutex_lock(&self->_lock);
    if (!self->_threadIsRunning){
        pthread_create(&self->_thread, NULL, (void * (*)(void *))remoteHostThread, (void *)CFBridgingRetain(self));
    }
    pthread_mutex_unlock(&self->_lock);
}

- (void)lock {
    pthread_mutex_lock(&self->_lock);
}

- (void)unlock {
    pthread_mutex_unlock(&self->_lock);
}

- (void)runThread {
    pthread_mutex_lock(&self->_threadLock);
    self->_threadIsRunning = YES;
    pthread_mutex_unlock(&self->_threadLock);
    
    while (self->_rawQueuedPackets.count != 0){
        NSMutableArray *packetsToRemove = [NSMutableArray array];
        
        pthread_mutex_lock(&self->_lock);
        for (int i = 0; i < SLIDING_WINDOW; i++){
            RDPPacket *packet = [_rawQueuedPackets objectAtIndex:i];
            if (packet.acknowledged){
                [packetsToRemove insertObject:@(i) atIndex:0];
                continue;
            }
            
            if (!packet.sent){
                [[RDPLayer sharedInstance] sendPacket:packet];
            }
        }
        
        for (NSNumber *num in packetsToRemove){
            [_rawQueuedPackets removeObjectAtIndex:num.integerValue];
        }
        pthread_mutex_lock(&self->_lock);
        usleep(100);
    }
    
    pthread_mutex_lock(&self->_threadLock);
    self->_threadIsRunning = NO;
    pthread_mutex_unlock(&self->_threadLock);
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

- (void)queuePacket:(RDPPacket *)packet {
    NSMutableArray *queueArray = [self->_queuedPackets objectForKey:@(packet.seqNum)];
    if (!queueArray){
        queueArray = [NSMutableArray array];
        [self->_queuedPackets setObject:queueArray forKey:@(packet.seqNum)];
    }
    [queueArray addObject:packet];
    [self sortPackets:queueArray];
    
    [_rawQueuedPackets addObject:packet];
}
@end
