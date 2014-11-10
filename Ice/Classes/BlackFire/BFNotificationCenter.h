//
//  BFNotificationCenter.h
//  BlackFire
//
//  Created by Antwan van Houdt on 11/28/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BFSoundSet;

extern NSString *BFSoundSetPathDefaultsKey;
extern NSString *BFSoundVolumeDefaultsKey;

@interface BFNotificationCenter : NSObject

+ (id)defaultNotificationCenter;

//-------------------------------------------------------------------------------
// Sounds


- (void)updateSoundVolume;
- (CGFloat)soundVolume;
- (void)setSoundSet:(BFSoundSet *)soundSet;
- (void)playConnectedSound;
- (void)playOnlineSound;
- (void)playOfflineSound;
- (void)playReceivedSound;
- (void)playSendSound;
- (void)playDemoSound;

//-------------------------------------------------------------------------------
// Growl

- (void)postNotificationWithTitle:(NSString *)notificationTitle body:(NSString *)body;
- (void)postNotificationWithTitle:(NSString *)notificationTitle body:(NSString *)body context:(id)context;


//------------------------------------------------------------------------------
// Dock Icon

- (void)addBadgeCount:(NSUInteger)add;
- (void)deleteBadgeCount:(NSUInteger)remove;

@end
