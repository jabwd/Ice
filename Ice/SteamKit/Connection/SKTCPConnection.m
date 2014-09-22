//
//  SKTCPConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKTCPConnection.h"
#import "SKPacket.h"

@implementation SKTCPConnection

- (id)initWithAddress:(NSString *)address
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
		NSString *_host = [comp objectAtIndex:0];
		UInt16 _port = (UInt16)[[comp objectAtIndex:1] integerValue];
		
		_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		
		NSError *socketError = nil;
		if( ![_socket connectToHost:_host onPort:_port error:&socketError] )
		{
			NSLog(@"Error on connecting %@", socketError);
			[self release];
			return nil;
		}
	}
	return self;
}

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
	SKPacket *packet = [[SKPacket connectPacket] retain];
	[self sendData:[packet generate]];
	[packet release];
}

- (void)sendData:(NSData *)data
{
	[super sendData:nil];
	[_socket writeData:data withTimeout:20 tag:0];
}


#pragma mark - TCPSocket delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	NSLog(@"Connected to host: %@", host);
	[_socket readDataWithTimeout:-1 tag:0];
	[self connect];
	/*NSMutableData *data = [[NSMutableData alloc] init];
	UInt16 len = 0x00;
	UInt32 magic = 0x31305456;
	[data appendBytes:&len length:2];
	[data appendBytes:&magic length:4];
	[_socket writeData:data withTimeout:-1 tag:0];
	[data release];*/
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
	NSLog(@"Socket did disconnect");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	NSLog(@"Sent some data");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"Got data: %@", data);
	[_socket readDataWithTimeout:-1 tag:0];
}

@end
