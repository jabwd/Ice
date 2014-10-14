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
			[_connection removeBytesOfLength:(first+8)];
		}
		else if( first == SKPacketUDPMagicHeader )
		{
			//packet = [SKPacket packetByDecodingUDPBuffer:buffer error:nil];
		}
		
		if( packet )
		{
			switch(packet.type)
			{
				case SKPacketTypeConnectChallenge:
				{
					SKPacket *responsePacket = [[SKPacket connectChallengePacket:packet.data] retain];
					[_connection sendPacket:responsePacket];
					[responsePacket release];
				}
					break;
					
				case SKPacketTypeClientDestination:
				{
					_connection.destination = packet.source;
					DLog(@"=> Received destination: %u", _connection.destination);
				}
					break;
					
				case SKPacketTypeEncryptionRequest:
				{
					SKPacket *encryptionResponse = [[SKPacket encryptionResponsePacket:_connection.session.sessionKey tcp:true] retain];
					[_connection sendPacket:encryptionResponse];
					[encryptionResponse release];
				}
					break;
					
				case SKPacketTypeEncryptionAccepted:
				{
					DLog(@"Encryption challenge accepted, starting login sequence");
					[_connection.session logIn];
				}
					break;
					
				case SKPacketTypeClient28ByteStream:
				{
					// we don't really need this packet, we don't really care it seems.
					// you are probably supposed to use this as some knid of salt in the sessionID
					// but I don't really know how much it actually matters.
					static BOOL first = true;
					if( first )
					{
						SKPacket *encryptionResponse = [[SKPacket encryptionResponsePacket:_connection.session.sessionKey tcp:false] retain];
						encryptionResponse.destination = _connection.destination;
						[_connection sendPacket:encryptionResponse];
						[encryptionResponse release];
						first = true;
					}
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
