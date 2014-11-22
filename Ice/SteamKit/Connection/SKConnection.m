//
//  SKConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKConnection.h"
#import "SKPacket.h"
#import "SKPacketScanner.h"

@implementation SKConnection

+ (NSString *)connectionStatusToString:(SKConnectionStatus)status
{
    switch(status)
    {
        case SKConnectionStatusOffline:
            return @"Connection Offline";
        case SKConnectionStatusConnecting:
            return @"Connection Connecting";
        case SKConnectionStatusDisconnecting:
            return @"Connection Disconnecting";
        case SKConnectionStatusOnline:
            return @"Connection Online";
        default:
            return @"Unknown connection status";
    }
    return nil;
}

- (id)initWithAddress:(NSString *)address session:(SKSession *)session
{
	if( (self = [super init]) )
	{
		// Parse the server address into a host
		// and a port
		NSArray *comp = [address componentsSeparatedByString:@":"];
		if( [comp count] != 2 )
		{
			NSLog(@"Incorrect server address given! %@", address);
			[self release];
			return nil;
		}
		_host		= [[comp objectAtIndex:0] retain];
		_port		= (UInt16)[[comp objectAtIndex:1] integerValue];
		_session	= [session retain];
		_scanner	= [[SKPacketScanner alloc] initWithConnection:self];
		_status		= SKConnectionStatusOffline;
		_buffer		= [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_session release];
	_session = nil;
	[_host release];
	_host = nil;
	[_buffer release];
	_buffer = nil;
	[_scanner release];
	_scanner = nil;
    [super dealloc];
}

#pragma mark - Connection & Status

- (SKConnectionStatus)status
{
    return _status;
}

- (void)setSession:(SKSession *)session
{
	[_session release];
	_session = [session retain];
}

- (void)connect
{
    if( [self status] != SKConnectionStatusOffline )
    {
        NSLog(@"Connection cannot connect while status is %@",
              [SKConnection connectionStatusToString:[self status]]);
        return;
    }
	_status = SKConnectionStatusConnecting;
}

- (void)disconnect
{
	[_scanner release];
	_scanner = nil;
	[_session release];
	_session = nil;
	
	_status = SKConnectionStatusDisconnecting;
}

- (void)sendData:(NSData *)data
{
    if( _status != SKConnectionStatusOnline || [data length] < 1 )
    {
        return;
    }
}

- (void)sendPacket:(SKPacket *)packet
{
	[self sendData:packet.raw];
}

- (void)removeBytesOfLength:(NSUInteger)length
{
	[_buffer replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
	DLog(@"Buffer size: %lu", [_buffer length]);
}

@end
