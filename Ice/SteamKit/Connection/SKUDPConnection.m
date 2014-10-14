//
//  SKUDPConnection.m
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKUDPConnection.h"
#import "SKPacket.h"
#import <netinet/in.h>
#import <arpa/inet.h>
#import "SKSession.h"
#import "SKPacketScanner.h"

@implementation SKUDPConnection

+ (NSArray *)knownServerList
{
	return @[
		@"208.64.200.202:27018",
		@"146.66.155.9:27017",
		@"72.165.61.185:27017",
		@"146.66.152.12:27017"
	];
}

- (id)initWithAddress:(NSString *)address
{
	if( (self = [super initWithAddress:address]) )
	{
		_sequence	= 0;
		_recvSeq	= 0;
	}
	return self;
}

- (void)dealloc
{
	[_session release];
	_session = nil;
	[_UDPSocket release];
	_UDPSocket = nil;
	[super dealloc];
}

#pragma mark - Opening the connection

- (void)connect
{
	[super connect];
	
	// Setup the socket for listening and sending
	[_UDPSocket release];
	_UDPSocket = nil;
	_UDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	NSError *socketError = nil;
	[_UDPSocket enableBroadcast:YES error:nil];
	if( ![_UDPSocket bindToPort:0 error:&socketError] )
	{
		NSLog(@"Error binding socket %@", socketError);
	}
	
	if( ![_UDPSocket connectToHost:_host onPort:_port error:&socketError] )
	{
		NSLog(@"Unable to connect to host %@ %@", _host, socketError);
	}
	
	if( ![_UDPSocket beginReceiving:&socketError] )
	{
		NSLog(@"Unable to start receviing data %@", socketError);
	}
}

- (void)disconnect
{
	[super disconnect];
	[_UDPSocket close];
	[_UDPSocket release];
	_UDPSocket = nil;
}

- (void)sendData:(NSData *)data
{
	[super sendData:nil];
	[_UDPSocket sendData:data withTimeout:-1 tag:0];
}

#pragma mark - UDPSocket delegate

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
	NSLog(@"Socket closed %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
	[_buffer appendData:data];
	[_scanner checkForPacket:_buffer];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
	_recvSeq	= 1;
	_sequence	= 1;
	SKPacket *p = [[SKPacket connectPacket] retain];
	[self sendPacket:p];
	[p release];
}

@end
