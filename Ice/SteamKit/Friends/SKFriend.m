//
//  SKFriend.m
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKFriend.h"

@implementation SKFriend

- (void)dealloc
{
	[_displayName release];
	_displayName = nil;
	[_username release];
	_username = nil;
	[_password release];
	_password = nil;
	[_countryCode release];
	_countryCode = nil;
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
	return [NSString stringWithFormat:@"[SKFriend displayName=%@ Country=%@ Email=%@]", _displayName, _countryCode, _email];
}

@end
