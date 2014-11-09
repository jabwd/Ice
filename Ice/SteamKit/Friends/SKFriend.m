//
//  SKFriend.m
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKFriend.h"
#import "SKSteamID.h"

@implementation SKFriend

- (id)initWithBody:(NSDictionary *)body
{
	if( (self = [super init]) )
	{
		_steamID		= [[SKSteamID alloc] initWithRawSteamID:[body[@"1"] unsignedIntegerValue]];
		_displayName	= [body[@"15"] retain];
		_lastLogoff		= [body[@"45"] unsignedIntValue];
		_lastLogon		= [body[@"46"] unsignedIntValue];
		_avatarHash		= [body[@"31"] retain];
		_gameName		= [body[@"55"] retain];
		_appID			= [body[@"3"] unsignedIntValue];
	}
	return self;
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
	[super dealloc];
}

- (NSString *)displayName
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

- (void)setDisplayName:(NSString *)displayName
{
	[_displayName release];
	_displayName = [displayName retain];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKFriend displayName=%@ steamID=%@]", _displayName, _steamID];
}

@end
