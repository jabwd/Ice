//
//  BFIdleTimeManager.h
//  BlackFire
//
//  Created by Mark Douma on 1/31/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <ApplicationServices/ApplicationServices.h>

@protocol BFIdleTimeManagerDelegate <NSObject>
- (void)userWentAway;
- (void)userBecameActive;
@end

@interface BFIdleTimeManager : NSObject 

@property (assign) id <BFIdleTimeManagerDelegate> delegate;

+ (BFIdleTimeManager *)defaultManager;
- (void)setSetAwayStatusAutomatically:(BOOL)shouldSetAutomatically;

@end
