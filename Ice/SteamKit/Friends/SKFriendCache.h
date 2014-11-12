//
//  SKFriendCache.h
//  Ice
//
//  Created by Antwan van Houdt on 12/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKFriend;

@interface SKFriendCache : NSObject
{
	NSMutableDictionary *_storage;
}

+ (id)sharedCache;

- (NSString *)playerNameForFriend:(SKFriend *)remoteFriend;
- (void)setPlayerNameForFriend:(SKFriend *)remoteFriend;

@end
