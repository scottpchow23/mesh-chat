//
//  RDPLayerRemoteHost.m
//  test-rdp
//
//  Created by CoolStar on 2/8/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

#import "RDPLayerRemoteHost.h"
#import <pthread.h>

@implementation RDPLayerRemoteHost
- (instancetype)init {
    self = [super init];
    if (self){
        self.threadIsRunning = false;
        pthread_mutex_t threadLock;
        pthread_mutex_init(&threadLock, NULL);
        self.threadLock = threadLock;
        self.thread = NULL;
    }
    return self;
}

- (void)startThread {
    if (self.threadIsRunning){
        return;
    }
    
}
@end
