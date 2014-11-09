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

@end
