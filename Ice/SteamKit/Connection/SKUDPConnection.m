//
//  SKUDPConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKUDPConnection.h"

@implementation SKUDPConnection

+ (NSArray *)knownServerList
{
	return @[
		@"a server"
	];
}

- (id)initWithServerAddress:(NSString *)server
{
	if( (self = [super init]) )
	{
		
	}
	return self;
}

- (id)init
{
	NSString *address = [[[self class] knownServerList] objectAtIndex:0];
	return [self initWithServerAddress:address];
}

@end
