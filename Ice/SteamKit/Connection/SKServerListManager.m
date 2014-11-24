//
//  SKServerListManager.m
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKServerListManager.h"
#import "SKSentryFile.h"
#import <stdlib.h>

@implementation SKServerListManager

- (id)initWithCache
{
	if( (self = [super init]) )
	{
		NSString *path		= [[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"servers.plist"];
		_list = [[NSMutableArray alloc] initWithContentsOfFile:path];
		if( !_list )
		{
			DLog(@"[Notice] no server list cache available");
		}
	}
	return self;
}

- (void)dealloc
{
	[_list release];
	_list = nil;
	[super dealloc];
}

- (void)addServer:(UInt32)IP port:(UInt16)port
{
	if( port != 27017 )
	{
		return; // Ignore the rest for now...
	}
	if( !_list )
	{
		_list = [[NSMutableArray alloc] init];
	}
	NSString *ipStr = [[NSString alloc] initWithFormat:@"%u.%u.%u.%u:%u", ((IP >> 24) & 0xFF),
					   ((IP >> 16) & 0xFF),
					   ((IP >> 8) & 0xFF),
					   ((IP) & 0xFF),port];
	
	[_list addObject:ipStr];
	[ipStr release];
}

- (void)save
{
	NSString *path		= [[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"servers.plist"];
	NSData *saveData	= [NSPropertyListSerialization dataWithPropertyList:_list format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
	[saveData writeToFile:path atomically:NO];
	DLog(@"=> Wrote a new server list");
}

- (NSString *)getRandomAddress
{
	if( !_list )
	{
		return @"146.66.155.9:27017"; // random placeholder.
	}
	UInt32 max = (UInt32)[_list count];
	char index = arc4random_uniform(max);
	return _list[index];
}

@end
