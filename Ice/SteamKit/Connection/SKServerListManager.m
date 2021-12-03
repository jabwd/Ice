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

+ (NSString *)cacheFilePath
{
	static NSString *path = nil;
	if( !path )
	{
		path = [[[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"servers.plist"] retain];
	}
	return path;
}

+ (BOOL)needsNewList
{
	if( [[NSFileManager defaultManager] fileExistsAtPath:[SKServerListManager cacheFilePath]] )
	{
		return NO;
	}
	return YES;
}

- (id)initWithCache
{
	if( (self = [super init]) )
	{
		_list = [[NSMutableArray alloc] initWithContentsOfFile:[SKServerListManager cacheFilePath]];
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

- (void)optimize
{
	for(NSString *hostName in _list)
	{
		SimplePing *pinger = [[SimplePing simplePingWithHostName:hostName] retain];
		[pinger setDelegate:self];
		[pinger sendPingWithData:nil];
	}
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

#pragma mark - Simple ping delegate

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
	[pinger setDelegate:nil];
	[pinger release];
	[pinger stop];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
	[pinger setDelegate:nil];
	[pinger release];
	DLog(@"=> Pinging failed %@", error);
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
	[pinger setDelegate:nil];
	[pinger stop];
	[pinger release];
	NSLog(@"#%u received", (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber) );
}

@end
