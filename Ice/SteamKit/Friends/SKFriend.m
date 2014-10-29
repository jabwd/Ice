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

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKFriend displayName=%@ Country=%@ Email=%@]", _displayName, _countryCode, _email];
}

@end
