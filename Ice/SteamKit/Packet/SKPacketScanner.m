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
#import "SKProtobufScanner.h"
#import "NSData_SteamKitAdditions.h"
#import "NSMutableData_XfireAdditions.h"

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
			[self handlePacket:packet];
		}
	}
}

- (void)handlePacket:(SKPacket *)packet
{
	switch(packet.msgType)
	{
		case SKMsgTypeMulti:
		{
			NSLog(@"Received a multi packet %@", packet.data);
			//NSLog(@"First varint: %u", (unsigned int)[SKProtobufScanner readVarint:packet.data]);
			UInt32 sizeUnzipped = 0;
			[packet.data getBytes:&sizeUnzipped range:NSMakeRange(0x04, 0x04)];
			if( sizeUnzipped > 0 )
			{
				DLog(@"Compressed packet detected, no way of handling this yet!!!");
			}
			else
			{
				NSMutableData *buffer = [[NSMutableData alloc] initWithData:packet.data];
				[buffer removeBytes:14];
				while( [buffer length] > 0 )
				{
					UInt32 blockSize = [buffer getUInt32];
					if( blockSize > [buffer length] )
					{
						NSLog(@"Error in scanning multi packet, blockSize %u exceeds buffer size", blockSize);
						[buffer release];
						return;
					}
					NSData *subData = [[buffer subdataWithRange:NSMakeRange(4, blockSize)] retain];
					[buffer removeBytes:(blockSize+4)];
					
					// Create a new packet with the new subdata:
					SKPacket *packet = [SKPacket packetByDecodingTCPBuffer:subData sessionKey:nil error:nil];
					DLog(@"Found a packet in multi: %@", packet);
					[self handlePacket:packet];
					[subData release];
				}
				[buffer release];
			}
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
			NSLog(@"LogOn Response: %@", packet);
			
			SKProtobufScanner *scanner = [[SKProtobufScanner alloc] initWithData:packet.data];
			
			[scanner release];
		}
			break;
			
		default:
			NSLog(@"Unhandled packet: %@", packet);
			break;
	}
}


@end
