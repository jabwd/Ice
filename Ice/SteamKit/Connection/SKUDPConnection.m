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

@implementation SKUDPConnection

+ (NSArray *)knownServerList
{
	return @[
		@"146.66.155.9:27017",
		@"72.165.61.185:27017",
		@"146.66.152.12:27017"
	];
}

- (id)initWithServerAddress:(NSString *)server
{
	if( (self = [super init]) )
	{
		// Parse the server address into a host
		// and a port
		NSArray *comp = [server componentsSeparatedByString:@":"];
		if( [comp count] != 2 )
		{
			NSLog(@"Incorrect server address given! %@", server);
			[self release];
			return nil;
		}
		_host = [comp objectAtIndex:0];
		_port = (UInt16)[[comp objectAtIndex:1] integerValue];
		
		
		// Setup the socket for listening and sending
		_UDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		NSError *socketError = nil;
		[_UDPSocket enableBroadcast:YES error:nil];
		if( ![_UDPSocket bindToPort:0 error:&socketError] )
		{
			NSLog(@"Error binding socket %@", socketError);
			[self release];
			return nil;
		}
		
		if( ![_UDPSocket connectToHost:_host onPort:_port error:&socketError] )
		{
			NSLog(@"Unable to connect to host %@ %@", _host, socketError);
			[self release];
			return nil;
		}
		
		if( ![_UDPSocket beginReceiving:&socketError] )
		{
			NSLog(@"Unable to start receviing data %@", socketError);
			[self release];
			return nil;
		}
		NSLog(@"Setup complete");
	}
	return self;
}

- (id)init
{
	NSString *address = [[[self class] knownServerList] objectAtIndex:0];
	return [self initWithServerAddress:address];
}

- (void)dealloc
{
	[_UDPSocket release];
	_UDPSocket = nil;
	[super dealloc];
}

#pragma mark - Opening the connection

- (void)connect
{
	[super connect];
	SKPacket *p = [[SKPacket connectPacket] retain];
	NSData *data = [p generate];
	[self sendData:data];
	[p release];
}

- (void)disconnect
{
	[super disconnect];
}

- (void)sendData:(NSData *)data
{
	[super sendData:nil];
	[_UDPSocket sendData:data withTimeout:-1 tag:0];
}

- (void)sendPacket:(SKPacket *)packet
{
	NSLog(@"S: %@", packet);
	
	// We need to up the sequence number of the packets we're sending
	// this seems to be sufficient for now.
	// if the packet has a predefined sequence number
	// the template probably requires it to be that way, ignore it
	if( packet.sequenceNumber == 0 )
	{
		_sequence++;
		packet.sequenceNumber = _sequence;
	}
	else
	{
		// Do nothing.
	}
	NSData *d = [packet generate];
	[self sendData:d];
}

- (void)checkForPacket
{
	if( [_buffer length] > SKPacketMinimumDataLength )
	{
		SKPacket *packet = [[SKPacket alloc] initWithData:_buffer];
		if( packet )
		{
			_recvSeq++; // this needs to be done in a better way somehow
						// but as of right now I do not know enough about the protocol yet.
			
			switch(packet.type)
			{
				case SKPacketTypeConnectChallenge:
				{
					NSLog(@"Received a connect challenge with payload: %@", packet.data);
					SKPacket *responsePacket = [[SKPacket connectChallengePacket:packet.data] retain];
					[self sendPacket:responsePacket];
					[responsePacket release];
				}
					break;
					
				case SKPacketTypeClientDestination:
				{
					NSLog(@"Received future destination packet: %@", packet);
					_destination = packet.source;
					NSLog(@"=> Now using %u as future destination", _destination);
					
				}
					break;
					
				case SKPackettypeClient28ByteStream:
				{
					NSLog(@"Received byte stream packet: %@", packet);
					if( packet.sequenceNumber != _recvSeq )
					{
						NSLog(@"Error: recvSeq of the byte stream packet != %u", _recvSeq);
					}
				}
					
				default:
					NSLog(@"Unhandled packet: %@", packet);
					break;
			}
			NSLog(@"Recv sequence number: %u", _recvSeq);
		}
		[packet release];
	}
}

#pragma mark - UDPSocket delegate

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
	NSLog(@"Socket closed %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
	[_buffer appendData:data];
	[self checkForPacket];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
	_recvSeq	= 0;
	_sequence	= 1;
	SKPacket *p = [[SKPacket connectPacket] retain];
	[self sendPacket:p];
	[p release];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	NSLog(@"Did not send data");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error
{
	NSLog(@"Socket did not connect");
}

@end
