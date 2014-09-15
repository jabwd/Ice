//
//  SKConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKConnection.h"

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

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Connected to steam server %@:%u", host, port);
	[sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"Received data: %@", data);
	NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"Data as string %@", str);
	[str release];
	[sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"Wrote some data with tag %lu", tag);
}

@end
