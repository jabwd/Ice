//
//  SKFriendCache.h
//  Ice
//
//  Created by Antwan van Houdt on 12/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKFriend;

@protocol SKAvatarDownloadDelegate <NSObject>
- (void)downloadDidFail;
- (void)downloadDidFinishWithPath:(NSString *)newPath;
@end

@interface SKFriendCache : NSObject
{
	NSMutableDictionary *_storage;
}

+ (id)sharedCache;

- (NSString *)playerNameForFriend:(SKFriend *)remoteFriend;
- (void)setPlayerNameForFriend:(SKFriend *)remoteFriend;

- (NSString *)avatarPathForFriend:(SKFriend <SKAvatarDownloadDelegate>*)remoteFriend;
- (void)downloadAvatarForFriend:(SKFriend <SKAvatarDownloadDelegate>*)remoteFriend;

- (NSData *)avatarHashForFriend:(SKFriend *)remoteFriend;
- (void)setAvatarHashForFriend:(SKFriend *)remoteFriend;

@end
