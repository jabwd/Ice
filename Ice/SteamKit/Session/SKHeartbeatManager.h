//
//  SKHeartbeatManager.h
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKHeartbeatManager : NSObject
{
	NSMutableArray *_timers;
}

+ (SKHeartbeatManager *)defaultManager;

- (void)addTimerForTime:(UInt32)seconds target:(id)target method:(SEL)method;
- (void)removeTimersForTarget:(id)target;

@end
