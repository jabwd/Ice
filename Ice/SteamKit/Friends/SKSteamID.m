//
//  SKSteamID.m
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKSteamID.h"

@implementation SKSteamID

- (id)initWithRawSteamID:(UInt64)rawID
{
	if( (self = [super init]) )
	{
		_rawSteamID = rawID;
	}
	return self;
}

- (UInt32)accountID
{
	return _rawSteamID & 0xFFFFFFFF;
}

- (UInt32)accountInstance
{
	return (_rawSteamID >> 32) & 0x000FFFFF;
}

- (UInt32)accountType
{
	return (_rawSteamID >> 52) & 0xF;
}

- (UInt32)accountUniverse
{
	return (_rawSteamID >> 56) & 0xF;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKSteamID type=%u id=%u uni=%u]", [self accountType], [self accountID], [self accountUniverse]];
}

@end
