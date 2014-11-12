//
//  SKFriendCache.m
//  Ice
//
//  Created by Antwan van Houdt on 12/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKFriendCache.h"
#import "SKSentryFile.h"
#import "SKFriend.h"
#import "SKSteamID.h"

@implementation SKFriendCache

+ (id)sharedCache
{
	static SKFriendCache *cacheInstance = nil;
	if( !cacheInstance )
	{
		cacheInstance = [[[self class] alloc] init];
	}
	return cacheInstance;
}

- (id)init
{
	if( (self = [super init]) )
	{
		NSString *path = [[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"friends.plist"];
		_storage = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
		if( !_storage )
		{
			_storage = [[NSMutableDictionary alloc] init];
		}
	}
	return self;
}

- (void)dealloc
{
	[_storage release];
	_storage = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (void)saveChanges
{
	DLog(@"=> Updating friends cache");
	
	NSString *path = [[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"friends.plist"];
	//[_storage writeToFile:path atomically:NO];
	NSData *outData = [NSPropertyListSerialization dataWithPropertyList:_storage
																 format:NSPropertyListBinaryFormat_v1_0
																options:0
																  error:nil];
	[outData writeToFile:path atomically:NO];
	DLog(@"=> Friends cache written to disk");
}

- (NSString *)playerNameForFriend:(SKFriend *)remoteFriend
{
	return _storage[[self keyForFriend:remoteFriend]];
}

- (void)setPlayerNameForFriend:(SKFriend *)remoteFriend
{
	_storage[[self keyForFriend:remoteFriend]] = remoteFriend.displayName;
	
	// Save the changes to disk, but make sure we do not over use this
	// method if there is no need for it. ( like on login, with rapid succession )
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(saveChanges) withObject:nil afterDelay:5.0f];
}

- (NSString *)keyForFriend:(SKFriend *)remoteFriend
{
	return [NSString stringWithFormat:@"%llu", remoteFriend.steamID.rawSteamID];
}

@end
