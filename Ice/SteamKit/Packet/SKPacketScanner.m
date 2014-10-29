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
#import "SKProtobufValue.h"

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
	SKPacket *packet	= nil;
	UInt32 first		= 0;
	UInt32 second		= 0;
	
	// Scan the packet header
	[buffer getBytes:&first length:4];
	[buffer getBytes:&second range:NSMakeRange(0x04, 4)];
	
	if( second == SKPacketTCPMagicHeader && first <= [buffer length] )
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
	else
	{
		NSLog(@"Packet size %u exceeds buffer size", first);
	}
	
	if( packet )
	{
		[self handlePacket:packet];
	}
}

- (void)handlePacket:(SKPacket *)packet
{
	switch(packet.msgType)
	{
		case SKMsgTypeMulti:
		{
			// Handle the multipacket
			SKProtobufScanner *scanner	= packet.scanner;
			NSNumber *sizeUnzipped		= scanner.body[@"1"];
			NSData *data				= scanner.body[@"2"];
			
			if( sizeUnzipped.unsignedIntegerValue > 0 )
			{
				DLog(@"Packet is compressed, decompressing");
				NSData *uncompressed = [data uncompressedDataWithSize:sizeUnzipped.intValue];
				if( [uncompressed length] != sizeUnzipped.unsignedIntegerValue )
				{
					DLog(@"Compressed data of different length than what was told %@ %@", uncompressed, sizeUnzipped);
				}
				data = uncompressed;
			}
			
			// Scan the actual packets
			NSMutableData *buffer = [[NSMutableData alloc] initWithData:data];
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
				[self handlePacket:packet];
				[subData release];
			}
			[buffer release];
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
			if( [[packet valueForFieldNumber:1] integerValue] == SKResultCodeAccountLogonDenied )
			{
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:SKLoginFailedSteamGuardNotificationName
				 object:nil
				 userInfo:@{@"email": [packet valueForFieldNumber:8]}];
			}
			else
			{
				NSLog(@"Unhandled logon response: %@", packet.scanner.body);
			}
		}
			break;
			
		case SKMsgTypeClientFriendsList:
		{
			NSLog(@"Received a friends list %@", packet.scanner.body);
		}
			break;
			
		case SKMsgTypeClientUpdateMachineAuth:
		{
			NSLog(@"Received sentryfile");
			
			NSDictionary *body	= packet.scanner.body;
			NSString *fileName	= body[@"1"];
			NSData *data		= body[@"4"];
			
			[_connection.session updateSentryFile:fileName data:data];
		}
			break;
			
		default:
			NSLog(@"Unhandled packet: %@", packet);
			break;
	}
}


@end
