//
//  SKGamesManager.h
//  Ice
//
//  Created by Antwan van Houdt on 23/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKGamesManager : NSObject
{
	NSMutableDictionary *_cache;
}

+ (instancetype)sharedManager;

- (void)downloadImageAtURL:(NSURL *)URL forID:(UInt32)appID;
- (NSImage *)imageForAppID:(UInt32)appID;

@end
