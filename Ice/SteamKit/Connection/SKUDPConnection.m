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
#import "NSData_XfireAdditions.h"

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
	NSLog(@"Sending %@", packet);
	
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
			// Properly empty the buffer
			NSUInteger packetSize = SKPacketMinimumDataLength+[packet.data length];
			[_buffer replaceBytesInRange:NSMakeRange(0, packetSize) withBytes:NULL length:0];
			
			switch(packet.type)
			{
				case SKPacketTypeConnectChallenge:
				{
					DLog(@"=> Received connect challenge packet, responding");
					SKPacket *responsePacket = [[SKPacket connectChallengePacket:packet.data] retain];
					[self sendPacket:responsePacket];
					[responsePacket release];
				}
					break;
					
				case SKPacketTypeClientDestination:
				{
					_destination = packet.source;
					DLog(@"=> Received destination: %u", _destination);
				}
					break;
					
				case SKPacketTypeClient28ByteStream:
				{
					NSLog(@"Received byte stream packet");
					if( packet.sequenceNumber != _recvSeq )
					{
						NSLog(@"Error: recvSeq of the byte stream packet != %u", _recvSeq);
					}
					// we don't really need this packet, we don't really care it seems.
					// you are probably supposed to use this as some knid of salt in the sessionID
					// but I don't really know how much it actually matters.
					
					SKPacket *encryptionResponse = [[SKPacket encryptionResponsePacket:nil] retain];
					[self sendPacket:encryptionResponse];
					[encryptionResponse release];
				}
					break;
					
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
	
	/*
	struct sockaddr_storage addr;
	socklen_t len = sizeof(addr);
	[address getBytes:&addr length:len];
	NSLog(@"Data received from %s:%d", inet_ntoa(((struct sockaddr_in*)&addr)->sin_addr),
          htons(((struct sockaddr_in*)&addr)->sin_port));
	*/
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
	_recvSeq	= 1;
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
