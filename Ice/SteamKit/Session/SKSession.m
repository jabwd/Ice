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
#import "NSData_SteamKitAdditions.h"

NSString *SKSessionStatusChangedNotificationName	= @"SKSessionStatusChanged";
NSString *SKLoginFailedSteamGuardNotificationName	= @"SKLoginFailedSteamGuard";

static const SKSession *_sharedSession = nil;

@implementation SKSession

+ (NSData *)generateSessionKey
{
	return [SKAESEncryption generateRandomData:32];
}

+ (id)sharedSession
{
	return _sharedSession;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_sessionKey			= [[NSData dataFromByteString:@"1a03a1af12a4825b3599e897815b53e9588d7a713983b64fc54801333ff4c658"] retain];
		_status				= SKSessionStatusOffline;
		_delegate			= nil;
		_sharedSession		= self;
	}
	return self;
}

- (void)dealloc
{
	_sharedSession = nil;
	[_sessionKey release];
	_sessionKey = nil;
	[_UDPConnection release];
	_UDPConnection = nil;
	[_TCPConnection release];
	_TCPConnection = nil;
	_delegate = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (void)setStatus:(SKSessionStatus)status
{
	_status = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:SKSessionStatusChangedNotificationName object:self];
	if( [_delegate respondsToSelector:@selector(sessionChangedStatus:)] )
	{
		[_delegate sessionChangedStatus:self];
	}
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
	_TCPConnection		= [[SKTCPConnection alloc] initWithAddress:[[SKUDPConnection knownServerList] objectAtIndex:0]];
	_TCPConnection.session = self;
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
	
	[self setStatus:SKSessionStatusOffline];
}

- (void)logIn
{
	DLog(@"Logging in with %@:%@", [self username], [self password]);
	SKPacket *packet = [SKPacket logOnPacket:[self username] password:[self password] language:@"english"];
	NSLog(@"%@ %@", packet.data, _sessionKey);
	NSData *final = [SKAESEncryption encryptPacketData:packet.data key:_sessionKey];
	packet.data = final;
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

@end