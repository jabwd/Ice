//
//  SKFriend.m
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKFriend.h"
#import "SKSteamID.h"
#import "SKPacket.h"
#import "SKSession.h"
#import "SKTCPConnection.h"
#import "SKGamesManager.h"

NSString *SKFriendOnlineStatusChangedNotification	= @"SKFriendOnlineStatusChanged";
NSString *SKDefaultAvatarImageName					= @"avatar-default";

@implementation SKFriend

- (id)initWithBody:(NSDictionary *)body
{
	if( (self = [super init]) )
	{
		_steamID		= [[SKSteamID alloc] initWithRawSteamID:[body[@"1"] unsignedIntegerValue]];
		_displayName	= [[[SKFriendCache sharedCache] playerNameForFriend:self] retain];
		
		if( body[@"15"] && ![_displayName isEqualToString:body[@"15"]] )
		{
			[_displayName release];
			_displayName = [body[@"15"] retain];
			[[SKFriendCache sharedCache] setPlayerNameForFriend:self];
		}
		
		_avatarHash		= [body[@"31"] retain];
		_gameName		= [body[@"55"] retain];
		
		_lastLogoff			= [body[@"45"] unsignedIntValue];
		_lastLogon			= [body[@"46"] unsignedIntValue];
		_appID				= [body[@"3"] unsignedIntValue];
		_status				= [body[@"2"] unsignedIntValue];
		_onlineInstances	= [body[@"7"] unsignedIntValue];
		_currentInstance	= [body[@"8"] unsignedIntValue];
	}
	return self;
}

- (id)initWithRawSteamID:(UInt64)steamID
{
	if( (self = [super init]) )
	{
		_steamID		= [[SKSteamID alloc] initWithRawSteamID:steamID];
		_displayName	= [[[SKFriendCache sharedCache] playerNameForFriend:self] retain];
		_avatarHash		= [[[SKFriendCache sharedCache] avatarHashForFriend:self] retain];
		_status			= SKPersonaStateOffline;
	}
	return self;
}

- (void)updateWithBodyInternal:(NSDictionary *)body isUpdate:(BOOL)isUpdate
{
	if( body[@"31"] && [body[@"31"] isKindOfClass:[NSData class]] && ![_avatarHash isEqualToData:body[@"31"]] )
	{
		[_avatarImage release];
		_avatarImage = nil;
		[_avatarHash release];
		_avatarHash = [body[@"31"] retain];
		[[SKFriendCache sharedCache] setAvatarHashForFriend:self];
	}
	
	if( body[@"15"] && ![_displayName isEqualToString:body[@"15"]] )
	{
		[_displayName release];
		_displayName = [body[@"15"] retain];
		[[SKFriendCache sharedCache] setPlayerNameForFriend:self];
	}
	
	if( body[@"55"] )
	{
		[_gameName release];
		_gameName = [body[@"55"] retain];
	}
	
	if( body[@"45"] || body[@"46"] )
	{
		_lastLogoff = [body[@"45"] unsignedIntValue];
		_lastLogon	= [body[@"46"] unsignedIntValue];
	}
	
	SKPersonaState oldStatus = SKPersonaStateMax;
	if( body[@"2"] )
	{
		SKPersonaState newStatus = [body[@"2"] unsignedIntValue];
		if( _status != SKPersonaStateMax && _status != newStatus )
		{
			oldStatus = _status;
		}
		_status = newStatus;
	}
	if( body[@"10"] )
	{
		_userSetStatus = [body[@"10"] boolValue];
	}
	
	if( body[@"3"] )
	{
		_appID = [body[@"3"] unsignedIntValue];
		
		// so we can display the game icon
		[_avatarImage release];
		_avatarImage = nil;
	}
	
	if( body[@"7"] )
	{
		UInt32 newOnlineInstance = [body[@"7"] unsignedIntValue];
		UInt32 newCurrentInstance = [body[@"8"] unsignedIntValue];
		if( newOnlineInstance != _onlineInstances )
		{
			_onlineInstances = newOnlineInstance;
			_currentInstance = newCurrentInstance;
			
			if( oldStatus == SKPersonaStateMax )
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendsListChangedNotificationName
																	object:self.session];
				if( _delegate )
				{
					if( [_delegate respondsToSelector:@selector(friendStatusDidChange)] )
					{
						[_delegate friendStatusDidChange];
					}
				}
			}
		}
		if( oldStatus == SKPersonaStateMax )
		{
			//[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendOnlineStatusChangedNotification
			//													object:self
			//												  userInfo:nil];
		}
	}
	
	if( oldStatus != SKPersonaStateMax )
	{
		if( _delegate )
		{
			if( [_delegate respondsToSelector:@selector(friendStatusDidChange)] )
			{
				[_delegate friendStatusDidChange];
			}
		}
		switch(_status)
		{
			case SKPersonaStateOffline:
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendOnlineStatusChangedNotification
																	object:self
																  userInfo:nil];
			}
				break;
				
			case SKPersonaStateOnline:
			{
				if( oldStatus == SKPersonaStateOffline )
				{
					[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendOnlineStatusChangedNotification
																		object:self
																	  userInfo:nil];
				}
			}
				break;
				
			case SKPersonaStateAway:		
			case SKPersonaStateBusy:
			case SKPersonaStateLookingToTrade:
			case SKPersonaStateSnooze:
			case SKPersonaStateLookingToPlay:
				break;
				
			default:
				break;
		}
	}
}

- (void)updateWithBody:(NSDictionary *)body
{
	[self updateWithBodyInternal:body isUpdate:YES];
}

- (void)dealloc
{
	[_gameName release];
	_gameName = nil;
	[_avatarHash release];
	_avatarHash = nil;
	[_displayName release];
	_displayName = nil;
	[_steamID release];
	_steamID = nil;
	[_session release];
	_session = nil;
	[_storedMessages release];
	_storedMessages = nil;
	[_avatarImage release];
	_avatarImage = nil;
	_delegate = nil;
	[super dealloc];
}

- (NSString *)displayNameString
{
	if( [_displayName length] > 0 )
	{
		return _displayName;
	}
	return @"Uknown user";
}

- (NSString *)statusDisplayString
{
	if( [_gameName length] > 0 && _appID != 0 )
	{
		if( _status == SKPersonaStateOnline )
		{
			return [NSString stringWithFormat:@"Playing %@", _gameName];
		}
		else
		{
			return [NSString stringWithFormat:@"%@, Playing %@", [self personaStateToString:_status], _gameName];
		}
	}
	if( _userSetStatus && _status != SKPersonaStateOnline )
	{
		return [NSString stringWithFormat:@"Self %@", [self personaStateToString:_status]];
	}
	return [self personaStateToString:_status];
}

- (BOOL)isMobile
{
	if( (_onlineInstances & 0x04) != 0 )
	{
		return YES;
	}
	//DLog(@"Instances: %u %u", _onlineInstances, (_onlineInstances & 0x4));
	return NO;
}

- (NSString *)personaStateToString:(SKPersonaState)state
{
	if( _isPendingFriend )
	{
		return @"Friend request pending";
	}
	switch(_status)
	{
		case SKPersonaStateOffline:
			return @"Offline";
			
		case SKPersonaStateAway:
			return @"Away";
			
		case SKPersonaStateBusy:
			return @"Busy";
			
		case SKPersonaStateLookingToPlay:
			return @"Looking to play";
			
		case SKPersonaStateLookingToTrade:
			return @"Looking to trade";
			
		case SKPersonaStateOnline:
			return @"Online";
			
		case SKPersonaStateSnooze:
			return @"Sleeping";
			
		default:
			return @"Offline";
	}
	return @"Offline";
}

- (NSImage *)avatarImage
{
	// Return the cached version so we do not
	// restart any download mechanics or whatever
	if( _avatarImage )
	{
		return _avatarImage;
	}
	
	/*if( _appID != 0 )
	{
		_avatarImage = [[[SKGamesManager sharedManager] imageForAppID:_appID] retain];
		if( _avatarImage )
		{
			return _avatarImage;
		}
		else
		{
			[_session requestAppInfo:_appID];
			return [NSImage imageNamed:SKDefaultAvatarImageName];
		}
	}*/
	
	if( !_avatarHash )
	{
		_avatarImage = [[NSImage imageNamed:SKDefaultAvatarImageName] retain];
	}
	else
	{
		// This method will automatically download the avatar image for us
		// and call the avatarDownloadDelegate method when required
		NSString *path = [[SKFriendCache sharedCache] avatarPathForFriend:self];
		
		// If we don't have a path we assign the image anyway so we don't
		// call avatarPathForFriend too often.
		if( path )
		{
			_avatarImage = [[NSImage alloc] initWithContentsOfFile:path];
		}
		else
		{
			_avatarImage = [[NSImage imageNamed:SKDefaultAvatarImageName] retain];
		}
	}
	return _avatarImage;
}

- (void)downloadDidFinishWithPath:(NSString *)newPath
{
	[_avatarImage release];
	_avatarImage = nil;
	_avatarImage = [[NSImage alloc] initWithContentsOfFile:newPath];
	if( !_avatarImage )
	{
		[self downloadDidFail];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendsListChangedNotificationName
														object:_session userInfo:@{@"remoteFriend":self}];
}

- (void)downloadDidFail
{
	[_avatarImage release];
	_avatarImage = nil;
	_avatarImage = [[NSImage imageNamed:SKDefaultAvatarImageName] retain];
}

- (void)setDelegate:(id<SKFriendChatDelegate>)delegate
{
	_delegate = delegate;
	
	if( _storedMessages )
	{
		for(NSDictionary *message in _storedMessages)
		{
			[self receivedChatMessageWithBody:message];
		}
		[_storedMessages release];
		_storedMessages = nil;
	}
}

- (id)delegate
{
	return _delegate;
}

- (void)removeAsFriend
{
	SKPacket *packet = [SKPacket removeFriendPacket:self];
	[_session.TCPConnection sendPacket:packet];
}

- (void)addAsFriend
{
	SKPacket *packet = [SKPacket addFriendPacket:self];
	[_session.TCPConnection sendPacket:packet];
}

#pragma mark - Avatar handling

- (NSURL *)avatarURL
{
	if( [_avatarHash length] < 1 )
	{
		// Should request it through the session
		return nil;
	}
	NSString *baseURL = @"http://media.steampowered.com/steamcommunity/public/images/avatars/";
	NSString *desc = [_avatarHash description];
	desc = [desc substringWithRange:NSMakeRange(1, [desc length]-2)];
	NSString *prefix = [desc substringWithRange:NSMakeRange(0, 2)];
	desc = [desc stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *URLString = [NSString stringWithFormat:@"%@/%@/%@_medium.jpg", baseURL, prefix, desc];
	return [NSURL URLWithString:URLString];
}

#pragma mark - Chatting

- (void)receivedChatMessageWithBody:(NSDictionary *)body
{
	if( !_delegate )
	{
		if( !_storedMessages )
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendNeedsChatWindowNotificationName
																object:self];
			_storedMessages = [[NSMutableArray alloc] init];
		}
		[_storedMessages addObject:body];
		return;
	}
	
	if( [_delegate respondsToSelector:@selector(friendDidReceiveMessage:date:type:)] )
	{
		SKChatEntryType entryType	= [body[@"2"] unsignedIntValue];
		NSString *message			= body[@"4"];
		NSDate *date				= [NSDate dateWithTimeIntervalSince1970:[body[@"5"] unsignedIntValue]];
		
		[_delegate friendDidReceiveMessage:message date:date type:entryType];
	}
}

- (void)sendMessage:(NSString *)message ofType:(SKChatEntryType)entryType
{
	SKPacket *chatPacket = [SKPacket sendMessagePacket:message
												friend:self
											   session:_session
												  type:entryType];
	[_session.TCPConnection sendPacket:chatPacket];
}

- (NSComparisonResult)displayNameSort:(SKFriend *)other
{
	if( self.appID != 0 && other.appID == 0 )
	{
		return NSOrderedAscending;
	}
	else if( self.appID != 0 && other.appID != 0 )
	{
		return [[self displayName] caseInsensitiveCompare:[other displayName]];
	}
	else if( self.appID == 0 && other.appID != 0 )
	{
		return NSOrderedDescending;
	}
	return [[self displayName] caseInsensitiveCompare:[other displayName]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKFriend displayName=%@ steamID=%@ avatarHash=%@ onlineInstance=%u currentInstance=%u]", _displayName, _steamID, _avatarHash, _onlineInstances, _currentInstance];
}

@end
