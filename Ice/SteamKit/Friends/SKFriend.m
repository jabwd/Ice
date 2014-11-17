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
#import "SKFriendCache.h"

NSString *SKFriendOnlineStatusChangedNotification = @"SKFriendOnlineStatusChanged";

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
		
		_lastLogoff		= [body[@"45"] unsignedIntValue];
		_lastLogon		= [body[@"46"] unsignedIntValue];
		_appID			= [body[@"3"] unsignedIntValue];
		_status			= [body[@"2"] unsignedIntValue];
	}
	return self;
}

- (id)initWithRawSteamID:(UInt64)steamID
{
	if( (self = [super init]) )
	{
		_steamID		= [[SKSteamID alloc] initWithRawSteamID:steamID];
		_displayName	= [[[SKFriendCache sharedCache] playerNameForFriend:self] retain];
		_status			= SKPersonaStateOffline;
	}
	return self;
}

- (void)updateWithBodyInternal:(NSDictionary *)body isUpdate:(BOOL)isUpdate
{
	if( body[@"31"] )
	{
		[_avatarHash release];
		_avatarHash = [body[@"31"] retain];
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
	
	if( body[@"45"] )
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
	
	if( body[@"3"] )
	{
		_appID = [body[@"3"] unsignedIntValue];
	}
	
	if( oldStatus != SKPersonaStateMax )
	{
		switch(_status)
		{
			case SKPersonaStateOffline:
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendOnlineStatusChangedNotification
																	object:nil
																  userInfo:@{@"friend":self}];
			}
				break;
				
			case SKPersonaStateOnline:
			{
				if( oldStatus == SKPersonaStateOffline )
				{
					[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendOnlineStatusChangedNotification
																		object:nil
																	  userInfo:@{@"friend":self}];
				}
			}
				break;
				
			case SKPersonaStateAway:		
			case SKPersonaStateBusy:
			case SKPersonaStateLookingToTrade:
			case SKPersonaStateSnooze:
			case SKPersonaStateLookingToPlay:
			{
			}
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
	[_username release];
	_username = nil;
	[_password release];
	_password = nil;
	[_countryCode release];
	_countryCode = nil;
	[_steamID release];
	_steamID = nil;
	[_session release];
	_session = nil;
	[_storedMessages release];
	_storedMessages = nil;
	_delegate = nil;
	[super dealloc];
}

- (NSString *)displayNameString
{
	if( [_displayName length] > 0 )
	{
		return _displayName;
	}
	else if( [_username length] > 0 )
	{
		return _username;
	}
	return @"Uknown user";
}

- (NSString *)statusDisplayString
{
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
	NSURL *URL = [self avatarURL];
	if( URL )
	{
		NSLog(@"Avatar: %@", URL);
		NSImage *test = [[NSImage alloc] initWithContentsOfURL:URL];
		return test;
	}
	return [NSImage imageNamed:@"avatar-default"];
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
	NSString *URLString = [NSString stringWithFormat:@"%@/%@/%@_medium.jpg", baseURL, [desc substringWithRange:NSMakeRange(0, 2)], desc];
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
	return [[self displayName] caseInsensitiveCompare:[other displayName]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKFriend displayName=%@ steamID=%@]", _displayName, _steamID];
}

@end
