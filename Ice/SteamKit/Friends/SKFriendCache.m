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

NSString *SKPlayerNameKey = @"name";
NSString *SKAvatarHashKey = @"avatarHash";

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

- (void)performSave
{
	// Save the changes to disk, but make sure we do not over use this
	// method if there is no need for it. ( like on login, with rapid succession )
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(saveChanges) withObject:nil afterDelay:5.0f];
}

- (void)saveChanges
{
	DLog(@"=> Updating friends cache");
	
	NSString *path = [[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"friends.plist"];
	NSData *outData = [NSPropertyListSerialization dataWithPropertyList:_storage
																 format:NSPropertyListBinaryFormat_v1_0
																options:0
																  error:nil];
	[outData writeToFile:path atomically:NO];
	DLog(@"=> Friends cache written to disk");
}

#pragma mark - Managing friend data

- (NSString *)playerNameForFriend:(SKFriend *)remoteFriend
{
	return _storage[[self keyForFriend:remoteFriend]][SKPlayerNameKey];
}

- (void)setPlayerNameForFriend:(SKFriend *)remoteFriend
{
	NSString *key = [self keyForFriend:remoteFriend];
	if( !_storage[key] )
	{
		_storage[key] = [[[NSMutableDictionary alloc] init] autorelease];
	}
	_storage[key][SKPlayerNameKey] = remoteFriend.displayName;
	[self performSave];
}

- (void)setAvatarHashForFriend:(SKFriend *)remoteFriend
{
	NSString *key = [self keyForFriend:remoteFriend];
	if( !_storage[key] )
	{
		_storage[key] = [[[NSMutableDictionary alloc] init] autorelease];
	}
	_storage[key][SKAvatarHashKey] = remoteFriend.avatarHash;
	[self performSave];
}

- (NSData *)avatarHashForFriend:(SKFriend *)remoteFriend
{
	return _storage[[self keyForFriend:remoteFriend]][SKAvatarHashKey];
}

#pragma mark - Managing avatar downloads

- (NSString *)suggestedAvatarPathForFriend:(SKFriend *)remoteFriend
{
	NSString *cacheDirectory	= [[SKSentryFile cacheFolderPath] stringByAppendingPathComponent:@"avatars"];
	[[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	NSString *desc				= [remoteFriend.avatarHash description];
	if( !desc )
	{
		// no avatar hash, can't download.
		DLog(@"[Error] no avatar hash for avatarPath");
		return nil;
	}
	NSString *hash				= [desc substringWithRange:NSMakeRange(1, [desc length]-2)];
	hash						= [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *avatarPath		= [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", hash]];
	return avatarPath;
}

- (NSString *)avatarPathForFriend:(SKFriend<SKAvatarDownloadDelegate> *)remoteFriend
{
	NSString *avatarPath = [self suggestedAvatarPathForFriend:remoteFriend];
	if( ![[NSFileManager defaultManager] fileExistsAtPath:avatarPath] )
	{
		[self downloadAvatarForFriend:remoteFriend];
		return nil;
	}
	return avatarPath;
}

- (void)downloadAvatarForFriend:(SKFriend<SKAvatarDownloadDelegate> *)remoteFriend
{
	NSURL *URL = [remoteFriend avatarURL];
	if( !URL )
	{
		DLog(@"[Error] attempting to download avatar image without a valid URL");
		return;
	}
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[remoteFriend retain];
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		if( !error )
		{
			NSString *finalPath = [self suggestedAvatarPathForFriend:remoteFriend];
			[data writeToFile:finalPath atomically:YES];
			DLog(@"=> Completed avatar download for %@", [remoteFriend displayName]);
			[remoteFriend downloadDidFinishWithPath:finalPath];
		}
		else
		{
			DLog(@"[Error] avatar download failed %@", error);
			[remoteFriend downloadDidFail];
		}
	}];
	[remoteFriend release];
	[request release];
																								
}

- (NSString *)keyForFriend:(SKFriend *)remoteFriend
{
	return [NSString stringWithFormat:@"%llu", remoteFriend.steamID.rawSteamID];
}

@end
