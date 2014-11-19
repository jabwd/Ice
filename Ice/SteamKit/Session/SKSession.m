//
//  SKSession.m
//  Ice
//
//  Created by Antwan van Houdt on 22/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKSession.h"
#import "SKAESEncryption.h"
#import "SKUDPConnection.h"
#import "SKTCPConnection.h"
#import "SKPacket.h"
#import "SKFriend.h"
#import "SKSteamID.h"
#import "NSData_SteamKitAdditions.h"

NSString *SKSessionStatusChangedNotificationName	= @"SKSessionStatusChanged";
NSString *SKLoginFailedSteamGuardNotificationName	= @"SKLoginFailedSteamGuard";
NSString *SKFriendsListChangedNotificationName		= @"SKFriendsListChangedNotification";
NSString *SKFriendNeedsChatWindowNotificationName	= @"SKFriendNeedsChatWindowNotification";

@implementation SKSession

+ (NSData *)generateSessionKey
{
	return [SKAESEncryption generateRandomData:32];
}

- (id)init
{
	if( (self = [super init]) )
	{
		_sessionKey			= [[NSData dataFromByteString:@"1a03a1af12a4825b3599e897815b53e9588d7a713983b64fc54801333ff4c658"] retain];
		_status				= SKSessionStatusOffline;
		_delegate			= nil;
		_rawSteamID			= 76561197960265728;
		_currentUser		= [[SKFriend alloc] init];
		
		_pendingFriends		= nil; // this is rarely needed, save some memory.
		_onlineFriends		= [[NSMutableArray alloc] init];
		_offlineFriends		= [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	if( _keepAliveTimer )
	{
		[_keepAliveTimer invalidate];
		_keepAliveTimer = nil;
	}
	[_sessionKey release];
	_sessionKey = nil;
	[_UDPConnection release];
	_UDPConnection = nil;
	[_TCPConnection release];
	_TCPConnection = nil;
	[_currentUser release];
	_currentUser = nil;
	[_loginKey release];
	_loginKey = nil;
	[_offlineFriends release];
	_offlineFriends = nil;
	[_onlineFriends release];
	_onlineFriends = nil;
	[_pendingFriends release];
	_pendingFriends = nil;
	_delegate = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (SKSessionStatus)status
{
	return _status;
}

- (void)setStatus:(SKSessionStatus)status
{
	_status = status;
	if( status == SKSessionStatusConnected )
	{
		if( _keepAliveTimerSeconds == 0 )
		{
			_keepAliveTimerSeconds = 10; // This seems to be a decent default
		}
		if( [_keepAliveTimer isValid] )
		{
			[_keepAliveTimer invalidate];
		}
		[_keepAliveTimer release];
		_keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:_keepAliveTimerSeconds
														   target:self
														 selector:@selector(keepAlive:)
														 userInfo:nil
														  repeats:YES];
		[_keepAliveTimer setTolerance:10];
		[self setUserStatus:SKPersonaStateOnline];
	}
	else if( status == SKSessionStatusDisconnecting )
	{
		[_keepAliveTimer invalidate];
		_keepAliveTimer = nil;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SKSessionStatusChangedNotificationName object:self];
	if( [_delegate respondsToSelector:@selector(sessionChangedStatus:)] )
	{
		[_delegate sessionChangedStatus:self];
	}
}

- (void)keepAlive:(NSTimer *)timer
{
	[_TCPConnection sendPacket:[SKPacket heartBeatPacket:self]];
}

#pragma mark - Connection Handling

- (void)connect
{
	if( _status != SKSessionStatusOffline )
	{
		DLog(@"[Error] Attempting to connect a session that is not offline!");
		return;
	}
	
	[_TCPConnection release];
	_TCPConnection		= [[SKTCPConnection alloc] initWithAddress:[[SKUDPConnection knownServerList] objectAtIndex:0]
													   session:self];
	[_TCPConnection connect];
	
	[self setStatus:SKSessionStatusConnecting];
}

- (void)disconnect
{
	[self setStatus:SKSessionStatusDisconnecting];
	_TCPConnection.session = nil;
	[_TCPConnection disconnect];
	[_TCPConnection release];
	_TCPConnection = nil;
	
	[_onlineFriends release];
	_onlineFriends = [[NSMutableArray alloc] init];
	[_offlineFriends release];
	_offlineFriends = [[NSMutableArray alloc] init];
	[_pendingFriends release];
	_pendingFriends = nil;
	[_currentUser release];
	_currentUser = nil;
	
	[self setStatus:SKSessionStatusOffline];
}

- (void)disconnectWithReason:(SKResultCode)reason
{
	[self disconnect];
	if( [_delegate respondsToSelector:@selector(session:didDisconnectWithReason:)] )
	{
		[_delegate session:self didDisconnectWithReason:reason];
	}
}

- (void)logIn
{
	SKPacket *packet = [SKPacket logOnPacket:self
									language:@"english"];
	[_TCPConnection sendPacket:packet];
}

- (void)updateSentryFile:(NSString *)fileName data:(NSData *)data
{
	if( [_delegate respondsToSelector:@selector(updateSentryFile:data:)] )
	{
		[_delegate updateSentryFile:fileName data:data];
	}
}

#pragma mark - User interaction

- (void)setUserStatus:(SKPersonaState)status
{
	_userStatus = status;
	
	SKPacket *changeStatusPacket = [SKPacket changeUserStatusPacket:self];
	[_TCPConnection sendPacket:changeStatusPacket];
}

- (SKPersonaState)userStatus
{
	return _userStatus;
}

#pragma mark - Setting up basic information

- (void)updateFriend:(NSDictionary *)packetData
{
	UInt64 steamID			= [packetData[@"1"] unsignedIntegerValue];
	SKFriend *remoteFriend	= [self friendForRawSteamID:steamID];
	if( !remoteFriend )
	{
		//DLog(@"Unhandled persona state: %@", packetData);
		return;
	}
	
	SKPersonaState oldStatus = remoteFriend.status;
	[remoteFriend updateWithBody:packetData];
	
	if( oldStatus == SKPersonaStateOffline && remoteFriend.status != SKPersonaStateOffline )
	{
		[_onlineFriends addObject:remoteFriend];
		[_offlineFriends removeObject:remoteFriend];
	}
	else if( remoteFriend.status == SKPersonaStateOffline && oldStatus != SKPersonaStateOffline )
	{
		[_offlineFriends addObject:remoteFriend];
		[_onlineFriends removeObject:remoteFriend];
	}
	[self sortFriendsList];
}

- (void)connectionAddFriend:(SKFriend *)remoteFriend
{
	remoteFriend.session = self;
	if( remoteFriend.displayName == nil )
	{
		[self requestFriendData:remoteFriend];
	}
	
	if( remoteFriend.avatarHash == nil )
	{
		SKPacket *packet = [SKPacket requestFriendDataPacket:remoteFriend flag:SKPersonaStateFlagPresence];
		[_TCPConnection sendPacket:packet];
	}
	
	if( remoteFriend.status == SKPersonaStateOffline || remoteFriend.status == SKPersonaStateMax )
	{
		[_offlineFriends addObject:remoteFriend];
	}
	else
	{
		[_onlineFriends addObject:remoteFriend];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendsListChangedNotificationName
														object:self];
}

- (void)addPendingFriend:(SKFriend *)pendingFriend
{
	SKPacket *packet = [SKPacket addFriendPacket:pendingFriend];
	[_TCPConnection sendPacket:packet];
}

- (void)sortFriendsList
{
	[_onlineFriends sortUsingSelector:@selector(displayNameSort:)];
	[_offlineFriends sortUsingSelector:@selector(displayNameSort:)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendsListChangedNotificationName
														object:self];
}

- (SKFriend *)friendForRawSteamID:(UInt64)rawSteamID
{
	for(SKFriend *remoteFriend in _onlineFriends)
	{
		if( remoteFriend.steamID.rawSteamID == rawSteamID )
		{
			return remoteFriend;
		}
	}
	for(SKFriend *remoteFriend in _offlineFriends)
	{
		if( remoteFriend.steamID.rawSteamID == rawSteamID )
		{
			return remoteFriend;
		}
	}
	return nil;
}

- (SKFriend *)friendForSteamID:(SKSteamID *)steamID
{
	return [self friendForRawSteamID:steamID.rawSteamID];
}

- (void)requestFriendProfile:(SKFriend *)remoteFriend
{
	SKPacket *packet = [SKPacket requestFriendProfilePacket:remoteFriend];
	[_TCPConnection sendPacket:packet];
}

- (void)requestFriendData:(SKFriend *)remoteFriend
{
	SKPacket *packet = [SKPacket requestFriendDataPacket:remoteFriend flag:SKPersonaStateFlagPlayerName];
	[_TCPConnection sendPacket:packet];
	
}

#pragma mark - Delegate stuff

- (NSString *)username
{
	if( [_delegate respondsToSelector:@selector(username)] )
	{
		return [_delegate username];
	}
	DLog(@"[Error] SKSession delegate does not implement -username, therefore logging in will not be possible!");
	return nil;
}

- (NSString *)password
{
	if( [_delegate respondsToSelector:@selector(password)] )
	{
		return [_delegate password];
	}
	DLog(@"[Error] SKSession delegate does not implement -password, therefore logging in will not be possible!");
	return nil;
}

- (NSString *)steamGuard
{
	if( [_delegate respondsToSelector:@selector(steamGuard)] )
	{
		return [_delegate steamGuard];
	}
	DLog(@"[Error] SKSession delegate does not implement -steamGuard, therefore logging in will not be possible");
	return nil;
}

@end
