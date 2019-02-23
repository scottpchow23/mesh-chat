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
typedef enum {
    SlidingWindowOperationNone = 0,
    SlidingWindowOperationIncrease = 1,
    SlidingWindowOperationDecrease = 2,
    SlidingWindowOperationReset = 4
} SlidingWindowOperation;

@interface RDPLayerRemoteHost() {
    uint32_t _slidingWindow;
    pthread_mutex_t _lock;
    pthread_mutex_t _threadLock;
    pthread_mutex_t _slidingWindowLock;
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
        self->_queuedSize = [NSMutableDictionary dictionary];
        self->_lastAck = [NSMutableDictionary dictionary];
        self->_lastAckCount = [NSMutableDictionary dictionary];
        self->_rawQueuedPackets = [NSMutableArray array];
        self->_slidingWindow = SLIDING_WINDOW_MIN;
        
        self->_threadIsRunning = false;
        pthread_mutex_init(&self->_lock, NULL);
        pthread_mutex_init(&self->_threadLock, NULL);
        pthread_mutex_init(&self->_slidingWindowLock, NULL);
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
    
    NSLog(@"Starting thread");
    
    while (self->_rawQueuedPackets.count != 0){
        NSMutableArray *packetsToRemove = [NSMutableArray array];
        
        pthread_mutex_lock(&self->_lock);
        pthread_mutex_lock(&self->_slidingWindowLock);
        int count = MIN(self->_slidingWindow, _rawQueuedPackets.count);
        pthread_mutex_unlock(&self->_slidingWindowLock);
        
        SlidingWindowOperation operation = SlidingWindowOperationNone;
        
        for (int i = 0; i < count; i++){
            RDPPacket *packet = [_rawQueuedPackets objectAtIndex:i];
            if (packet.acknowledged){
                NSLog(@"Packet marked as acknowledged!");
                [packetsToRemove insertObject:@(i) atIndex:0];
                operation |= SlidingWindowOperationIncrease;
                continue;
            }
            
            time_t now;
            time(&now);
            
            if (!packet.sent || (packet.sent && now > packet.sentTime + SLIDING_WINDOW_TIMEOUT)){
                if (packet.sent){
                    NSLog(@"Timeout on packet seq: %d; start=%d, len=%d", packet.seqNum, packet.start, packet.len);
                    operation |= SlidingWindowOperationReset;
                }
                [[RDPLayer sharedInstance] sendPacket:packet];
            }
        }
        
        for (NSNumber *num in packetsToRemove){
            [_rawQueuedPackets removeObjectAtIndex:num.integerValue];
        }
        
        if (operation & SlidingWindowOperationReset){
            [self resetSlidingWindow];
        } else if (operation & SlidingWindowOperationDecrease){
            [self decreaseSlidingWindow];
        } else if (operation & SlidingWindowOperationIncrease){
            [self increaseSlidingWindow];
        }
        pthread_mutex_unlock(&self->_lock);
        usleep(100);
    }
    
    NSLog(@"Exiting thread");
    
    pthread_mutex_lock(&self->_threadLock);
    self->_threadIsRunning = NO;
    pthread_mutex_unlock(&self->_threadLock);
}

- (void)increaseSlidingWindow {
    pthread_mutex_lock(&self->_slidingWindowLock);
    uint32_t oldSlidingWindow = self->_slidingWindow;
    self->_slidingWindow += 3;
    if (self->_slidingWindow >= SLIDING_WINDOW_MAX)
        self->_slidingWindow = SLIDING_WINDOW_MAX;
    NSLog(@"Increasing sliding window from %d to %d", oldSlidingWindow, self->_slidingWindow);
    pthread_mutex_unlock(&self->_slidingWindowLock);
}

- (void)decreaseSlidingWindow {
    pthread_mutex_lock(&self->_slidingWindowLock);
    uint32_t oldSlidingWindow = self->_slidingWindow;
    self->_slidingWindow /= 2;
    if (self->_slidingWindow <= SLIDING_WINDOW_MIN)
        self->_slidingWindow = SLIDING_WINDOW_MIN;
    NSLog(@"Decreasing sliding window from %d to %d", oldSlidingWindow, self->_slidingWindow);
    pthread_mutex_unlock(&self->_slidingWindowLock);
}

- (void)resetSlidingWindow {
    pthread_mutex_lock(&self->_slidingWindowLock);
    uint32_t oldSlidingWindow = self->_slidingWindow;
    self->_slidingWindow = SLIDING_WINDOW_MIN;
    NSLog(@"Resetting sliding window from %d to %d", oldSlidingWindow, self->_slidingWindow);
    pthread_mutex_unlock(&self->_slidingWindowLock);
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
    pthread_mutex_lock(&self->_lock);
    NSMutableArray *queueArray = [self->_queuedPackets objectForKey:@(packet.seqNum)];
    if (!queueArray){
        queueArray = [NSMutableArray array];
        [self->_queuedPackets setObject:queueArray forKey:@(packet.seqNum)];
    }
    [queueArray addObject:packet];
    [self sortPackets:queueArray];
    
    [_rawQueuedPackets addObject:packet];
    pthread_mutex_unlock(&self->_lock);
}
@end
