//
//  SKTCPConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKTCPConnection.h"
#import "SKPacket.h"
#import "SKPacketScanner.h"
#import "NSData_SteamKitAdditions.h"

@implementation SKTCPConnection

- (void)dealloc
{
	[_socket release];
	_socket = nil;
	[super dealloc];
}

#pragma mark - Connecting

- (void)connect
{
	[super connect];
	[_socket release];
	_socket = nil;
	_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSError *socketError = nil;
	if( ![_socket connectToHost:_host onPort:_port error:&socketError] )
	{
		NSLog(@"Error on connecting %@", socketError);
		[self disconnect];
	}
}

- (void)disconnect
{
	[super disconnect];
	[_socket disconnect];
	[_socket release];
	_socket = nil;
}

- (void)sendData:(NSData *)data
{
	// Performs some checks that might be handy
	[super sendData:nil];
	
	// Send the data over the socket
	[_socket writeData:data withTimeout:20 tag:0];
}


#pragma mark - TCPSocket delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	DLog(@"Connected to host: %@:%u", host, port);
	
	_status = SKConnectionStatusOnline;
	[_socket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	DLog(@"TCP Socket disconnected");
	[_session disconnect];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	[_buffer appendData:data];
	UInt32 length = [_buffer getUInt32];
	
	// Wait till we have enough data to scan the packet we received
	if( length <= [_buffer length] )
	{
		[_scanner checkForPacket:_buffer];
	}
	[_socket readDataWithTimeout:-1 tag:0];
}

@end
