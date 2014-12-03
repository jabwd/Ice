//
//  SKSession.m
//  Ice
//
//  Created by Antwan van Houdt on 22/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKSession.h"
#import "SKAESEncryption.h"
#import "SKTCPConnection.h"
#import "SKPacket.h"
#import "SKFriend.h"
#import "SKSteamID.h"
#import "NSData_SteamKitAdditions.h"
#import "SKServerListManager.h"

NSString *SKSessionStatusChangedNotificationName	= @"SKSessionStatusChanged";
NSString *SKLoginFailedSteamGuardNotificationName	= @"SKLoginFailedSteamGuard";
NSString *SKFriendsListChangedNotificationName		= @"SKFriendsListChangedNotification";
NSString *SKFriendNeedsChatWindowNotificationName	= @"SKFriendNeedsChatWindowNotification";

static SKSession *_currentSession = nil;

@implementation SKSession

+ (NSData *)generateSessionKey
{
	return [SKAESEncryption generateRandomData:32];
}

+ (SKSession *)currentSession
{
	return _currentSession;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_sessionKey			= [[SKSession generateSessionKey] retain];
		_status				= SKSessionStatusOffline;
		_delegate			= nil;
		_rawSteamID			= 76561197960265728;
		_currentUser		= [[SKFriend alloc] init];
		_currentSession		= self;
		
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
	_currentSession = nil;
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

- (void)requestAppInfo:(UInt32)appID
{
	SKPacket *packet = [SKPacket requestAppInfoPacket:appID session:self];
	[_TCPConnection sendPacket:packet];
}

#pragma mark - Connection Handling

- (void)connect
{
	if( _status != SKSessionStatusOffline )
	{
		DLog(@"[Error] Attempting to connect a session that is not offline!");
		return;
	}
	[self setStatus:SKSessionStatusConnecting];
	
	SKServerListManager *manager = [[SKServerListManager alloc] initWithCache];
	NSString *IP = [manager getRandomAddress];
	[manager release];
	DLog(@"=> Connecting to %@", IP);
	
	[_TCPConnection release];
	_TCPConnection		= [[SKTCPConnection alloc] initWithAddress:IP
													   session:self];
	[_TCPConnection connect];
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
	if( [_delegate respondsToSelector:@selector(session:didDisconnectWithReason:)] )
	{
		[_delegate session:self didDisconnectWithReason:reason];
	}
	[self disconnect];
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

- (void)setUserDisplayName:(NSString *)newName
{
	if( !newName )
	{
		return;
	}
	
	_currentUser.displayName = newName;
	
	SKPacket *changePacket = [SKPacket changeUserStatusPacket:self];
	[_TCPConnection sendPacket:changePacket];
}

#pragma mark - Setting up basic information

- (void)updateFriend:(NSDictionary *)packetData
{
	UInt64 steamID			= [packetData[@"1"] unsignedIntegerValue];
	SKFriend *remoteFriend	= [self friendForRawSteamID:steamID];
	if( !remoteFriend )
	{
		// Don't add your self.
		if( steamID == self.rawSteamID )
		{
			[_currentUser updateWithBody:packetData];
			return;
		}
		// At this point in time I do not know why this is happening.
		SKFriend *newFriend = [[SKFriend alloc] initWithRawSteamID:[packetData[@"1"] unsignedIntegerValue]];
		[newFriend updateWithBody:packetData];
		[self connectionAddFriend:newFriend moreComing:NO];
		[newFriend release];
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
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sortFriendsList) object:nil];
	[self performSelector:@selector(sortFriendsList) withObject:nil afterDelay:0.2f];
}

- (void)connectionAddFriend:(SKFriend *)remoteFriend moreComing:(BOOL)moreComing
{
	if( [self friendForSteamID:remoteFriend.steamID] )
	{
		// this also seems to be causing an issue!
		return;
	}
	remoteFriend.session = self;
	if( remoteFriend.displayName == nil )
	{
		[self requestFriendData:remoteFriend];
	}
	
	if( remoteFriend.avatarHash == nil )
	{
		// should maybe be changed later.
		//SKPacket *packet = [SKPacket requestFriendDataPacket:remoteFriend flag:SKPersonaStateFlagPresence];
		//[_TCPConnection sendPacket:packet];
	}
	
	if( remoteFriend.status == SKPersonaStateOffline || remoteFriend.status == SKPersonaStateMax )
	{
		[_offlineFriends addObject:remoteFriend];
	}
	else
	{
		[_onlineFriends addObject:remoteFriend];
	}
}

- (void)connectionRemoveFriend:(SKFriend *)remoteFriend
{
	[_offlineFriends	removeObject:remoteFriend];
	[_onlineFriends		removeObject:remoteFriend];
	
	[self sortFriendsList];
}

- (void)removePendingFriend:(SKFriend *)friend
{
	// Need to do a manual seek/remove as this can be a different pointer / object
	// than the SKFriend we already know ( SKFriend does not implement isEqual: )
	for(NSUInteger i = 0;i<[_pendingFriends count];i++)
	{
		SKFriend *c = _pendingFriends[i];
		if( c.steamID.rawSteamID == friend.steamID.rawSteamID )
		{
			c.isPendingFriend = NO; // this seems to cause an issue
									// so setting it specifically
			[_pendingFriends removeObjectAtIndex:i];
			if( [_pendingFriends count] == 0 )
			{
				// free up some memory
				[_pendingFriends release];
				_pendingFriends = nil;
			}
			return; // done here
		}
	}
}

- (void)addPendingFriend:(SKFriend *)pendingFriend
{
	if( !_pendingFriends )
	{
		_pendingFriends = [[NSMutableArray alloc] init];
	}
	pendingFriend.session = self;
	if( pendingFriend.displayName == nil )
	{
		[self requestFriendData:pendingFriend];
	}
	pendingFriend.isPendingFriend = YES;
	[_pendingFriends addObject:pendingFriend];
	
	[self sortFriendsList];
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
	for(SKFriend *remoteFriend in _pendingFriends)
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
	SKPacket *packet = [SKPacket requestFriendDataPacket:remoteFriend flag:SKPersonaStateFlagPlayerName|SKPersonaStateFlagPresence];
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
