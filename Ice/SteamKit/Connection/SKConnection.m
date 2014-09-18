//
//  SKConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKConnection.h"
#import "SKPacket.h"

#define CONNECTION_TIMEOUT  5000
#define MAGIC_HEADER        0x31305456 // VT01
#define TEST_SERVER         @"72.165.61.174"
#define TEST_SERVER_PORT    27017

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

- (id)init
{
    if( (self = [super init]) )
    {
        _socket		= [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _status		= SKConnectionStatusOffline;
		_buffer		= [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_socket release];
    _socket = nil;
	[_buffer release];
	_buffer = nil;
    [super dealloc];
}

#pragma mark - Connection & Status

- (SKConnectionStatus)status
{
    return _status;
}

- (void)connect
{
    if( [self status] != SKConnectionStatusOffline )
    {
        NSLog(@"Connection cannot connect while status is %@",
              [SKConnection connectionStatusToString:[self status]]);
        return;
    }
    
    NSError *socketErr = nil;
    if( ![_socket connectToHost:TEST_SERVER onPort:TEST_SERVER_PORT error:&socketErr] )
    {
        NSLog(@"Error on socket connect: %@", socketErr);
    }
}

- (void)disconnect
{
    if( [self status] != SKConnectionStatusConnecting &&
        [self status] != SKConnectionStatusOnline )
    {
        NSLog(@"Connection cannot disconnect while status is %@",
              [SKConnection connectionStatusToString:[self status]]);
        return;
    }
}

- (void)sendData:(NSData *)data
{
    if( _status != SKConnectionStatusOnline || [data length] < 1 )
    {
        return;
    }
    [_socket writeData:data withTimeout:-1 tag:_dataCount];
    _dataCount++;
}

- (void)checkForPacket
{
	BOOL shouldContinue		= NO;
	UInt32 packetLen			= 0;
	[_buffer getBytes:&packetLen length:sizeof(UInt32)];
	NSLog(@"Found a packet of length %u", (unsigned int)packetLen);
	
	// Check to see if we have enough data to scan this packet and create it
	if( [_buffer length] >= packetLen )
	{
		UInt32 doubleSize = sizeof(UInt32)*2;
		NSData *packetData = [_buffer subdataWithRange:NSMakeRange(doubleSize, packetLen)];
		[_buffer replaceBytesInRange:NSMakeRange(0, packetLen+doubleSize) withBytes:NULL length:0];
		SKPacket *packet = [[SKPacket alloc] initWithData:packetData];
		if( [packet isValid] )
		{
			shouldContinue = YES;
		}
		[self handlePacket:packet];
		[packet release];
	}
	
	// Make sure the buffer is empty of all available packets
	// that could be scanned
	if( [_buffer length] > 3 && shouldContinue )
	{
		[self checkForPacket];
	}
}

- (void)handlePacket:(SKPacket *)packet
{
	
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Connected to steam server %@:%u", host, port);
	[sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"Received data: %@", data);
	
	[_buffer appendData:data];
	[self checkForPacket];
	
	[sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"Wrote some data with tag %lu", tag);
}

@end
