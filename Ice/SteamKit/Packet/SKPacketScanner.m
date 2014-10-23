//
//  SKPacketScanner.m
//  Ice
//
//  Created by Antwan van Houdt on 14/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKPacketScanner.h"
#import "SKConnection.h"
#import "SKPacket.h"
#import "SKSession.h"
#import "SKAESEncryption.h"

@implementation SKPacketScanner

- (id)initWithConnection:(SKConnection *)connection
{
	if( (self = [super init]) )
	{
		_connection = [connection retain];
	}
	return self;
}

- (void)dealloc
{
	[_connection release];
	_connection = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (void)checkForPacket:(NSData *)buffer
{
	if( [buffer length] > SKPacketMinimumDataLength )
	{
		SKPacket *packet	= nil;
		UInt32 first		= 0;
		UInt32 second		= 0;
		
		// Scan the packet header
		[buffer getBytes:&first length:4];
		[buffer getBytes:&second range:NSMakeRange(0x04, 4)];
		
		if( second == SKPacketTCPMagicHeader )
		{
			packet = [SKPacket packetByDecodingTCPBuffer:[buffer subdataWithRange:NSMakeRange(0x08, first)]
											  sessionKey:_connection.session.sessionKey
												   error:nil];
			
			// Removes the packetdata from the connection's buffer.
			[_connection removeBytesOfLength:(first+8)];
		}
		else if( first == SKPacketUDPMagicHeader )
		{
			DLog(@"UDP Packets are not supported right now");
		}
		
		if( packet )
		{
			switch(packet.msgType)
			{
				case SKMsgTypeMulti:
				{
					NSLog(@"Received a multi packet");
				}
					break;
					
				case SKMsgTypeChannelEncryptRequest:
				{
					SKPacket *encryptionResponse = [[SKPacket encryptionResponsePacket:_connection.session.sessionKey] retain];
					[_connection sendPacket:encryptionResponse];
					[encryptionResponse release];
				}
					break;
					
				case SKMsgTypeChannelEncryptResult:
				{
					[_connection.session logIn];
				}
					break;
					
				case SKMsgTypeClientLogOnResponse:
				{
					
				}
					break;
					
				default:
					NSLog(@"Unhandled packet: %@", packet);
					break;
			}
		}
	}
}


@end
