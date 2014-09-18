//
//  SKUDPConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKUDPConnection.h"
#import "SKPacket.h"

@implementation SKUDPConnection

+ (NSArray *)knownServerList
{
	return @[
		@"146.66.152.12:27017"
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

#pragma mark - Opening the connection

- (void)connect
{
	
}

@end
