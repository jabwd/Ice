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
#import "SKFriend.h"
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
	SKSession *session = _connection.session;
	
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
			SKPacket *encryptionResponse = [[SKPacket encryptionResponsePacket:session.sessionKey] retain];
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
			session.rawSteamID = [packet.scanner.header[@"1"] unsignedIntegerValue];
			SKResultCode result = (SKResultCode)[[packet valueForFieldNumber:1] integerValue];
			switch(result)
			{
				case SKResultCodeAccountLogonDenied:
				{
					[[NSNotificationCenter defaultCenter]
					 postNotificationName:SKLoginFailedSteamGuardNotificationName
					 object:nil
					 userInfo:@{@"email": [packet valueForFieldNumber:8]}];
				}
					break;
					
				case SKResultCodeOK:
				{
					NSNumber *sessionID = [packet.scanner.header objectForKey:@"2"];
					session.sessionID = [sessionID unsignedIntValue];
					
					UInt32 keepAliveSeconds = [[packet valueForFieldNumber:2] intValue];
					session.keepAliveTimerSeconds = keepAliveSeconds;
					[_connection sendPacket:[SKPacket heartBeatPacket:session]];
				}
					break;
					
				default:
					DLog(@"Unhandled login response: %@", packet.scanner.body);
					break;
			}
		}
			break;
			
		case SKMsgTypeClientFriendsList:
		{
			NSLog(@"Received a friends list %@", packet.scanner.body);
			
			NSData *repeated = [packet valueForFieldNumber:2];
			if( [repeated length] > 0 )
			{
				NSLog(@"Result: %@", [packet.scanner scanRepeated:repeated]);
			}
		}
			break;
			
		case SKMsgTypeClientUpdateMachineAuth:
		{
			NSDictionary *body	= packet.scanner.body;
			NSString *fileName	= body[@"1"];
			//NSNumber *offset	= body[@"2"];
			NSNumber *length	= body[@"3"];
			NSData *data		= body[@"4"];
			NSNumber *sourceID	= packet.scanner.header[@"10"];
			//NSNumber *sessionID = packet.scanner.header[@"2"];
			
			session.targetID	= [sourceID unsignedIntegerValue];
			
			[_connection.session updateSentryFile:fileName data:data];
			SKPacket *packet = [SKPacket machineAuthResponsePacket:(UInt32)length.unsignedIntegerValue
														   session:session];
			[_connection sendPacket:packet];
		}
			break;
			
		case SKMsgTypeClientNewLoginKey:
		{
			UInt32 uniqueId		= (UInt32)[packet.scanner.body[@"1"] unsignedIntegerValue];
			NSString *loginKey	= packet.scanner.body[@"2"];
			
			NSNumber *sourceID	= packet.scanner.header[@"10"];
			if( sourceID )
			{
				DLog(@"Successfully set the sourceID: %@", sourceID);
				session.targetID	= [sourceID unsignedIntegerValue];
			}
			
			session.loginKey = loginKey;
			session.uniqueID = uniqueId;
			
			[_connection sendPacket:[SKPacket loginKeyAccepted:session]];
			
			[session setStatus:SKSessionStatusConnected];
		}
			break;
			
		case SKMsgTypeClientVACBanStatus:
		{
		}
			break;
			
		case SKMsgTypeClientServersAvailable:
			break;
			
		case SKMsgTypeClientAccountInfo:
		{
			session.currentUser.displayName = packet.scanner.body[@"1"];
			session.currentUser.countryCode = packet.scanner.body[@"2"];
		}
			break;
			
		case SKMsgTypeClientEmailAddrInfo:
		{
			session.currentUser.email = packet.scanner.body[@"1"];
		}
			break;
			
		case SKMsgTypeClientRequestedClientStats:
			break;
			
		case SKMsgTypeClientServerList:
		{
			//DLog(@"Received a server list %@ %@", packet.scanner.body, packet.scanner.header);
		}
			break;
			
		case SKMsgTypeClientFriendsGroupsList:
		{
			//DLog(@"Groups: %@ %@", packet.scanner.body, packet.scanner.header);
		}
			break;
			
		case SKMsgTypeClientPlayerNicknameList:
		{
			//DLog(@"Nicknamelist: %@ %@", packet.scanner.body, packet.scanner.header);
		}
			break;
			
		case SKMsgTypeClientFriendMsgIncoming:
		{
			NSString *message	= [packet valueForFieldNumber:4];
			SInt32 chatType		= [[packet valueForFieldNumber:2] intValue];
			UInt32 timestamp	= [[packet valueForFieldNumber:5] unsignedIntValue];
			UInt64 remoteID		= [[packet valueForFieldNumber:1] unsignedIntegerValue];
			NSDate *date		= [NSDate dateWithTimeIntervalSince1970:timestamp];
			
			NSLog(@"Received a chat message: %llu %@ %@:%d", remoteID, message, date, chatType);
		}
			break;
			
		case SKMsgTypeClientLicenseList:
		{
			/*NSData *repeatedFields = [packet valueForFieldNumber:2];
			if( [repeatedFields length] > 0 )
			{
				SKProtobufScanner *scanner	= [[SKProtobufScanner alloc] initWithData:nil];
				NSMutableData *body			= [[NSMutableData alloc] initWithData:repeatedFields];
				[scanner scanBody:body];
				NSLog(@"Repeated result: %@", scanner.body);
				[body release];
				[scanner release];
			}*/
		}
			break;
			
		case SKMsgTypeClientUpdateGuestPassesList:
		{
			// Unhandled for now
		}
			break;
			
		case SKMsgTypeClientWalletInfoUpdate:
		{
			//NSNumber *hasWallet = [packet valueForFieldNumber:1];
			//NSNumber *balance	= [packet valueForFieldNumber:2];
			//NSNumber *currency	= [packet valueForFieldNumber:3];
		}
			break;
			
		case SKMsgTypeClientSessionToken:
		{
			NSLog(@"=> Session Token received");
			// Don't really know what  the use for this packet is at the moment
			//DLog(@"Session token: %@ %@", packet.scanner.body, packet.scanner.header);
		}
			break;
			
		case SKMsgTypeClientIsLimitedAccount:
		{
			/*if( [[packet valueForFieldNumber:1] integerValue] == 1 )
			{
				DLog(@"Appears to be a limited account, do not know for what reason");
			}
			
			if( [[packet valueForFieldNumber:4] integerValue] == 1 )
			{
				DLog(@"=> This account is allowed to add friends");
			}*/
		}
			break;
			
		case SKMsgTypeClientGameConnectTokens:
		{
			// Unhandled for now
		}
			break;
			
		case SKMsgTypeClientCMList:
		{
			//UInt32 IP	= [packet.scanner.body[@"1"] unsignedIntValue];
			//UInt32 port = [packet.scanner.body[@"2"] unsignedIntValue];
			//DLog(@"Server List: %u.%u.%u.%u:%u", ((IP >> 24) & 0xFF), ((IP >> 16) & 0xFF), ((IP >> 8) & 0xFF), (IP & 0xFF), port);
		}
			break;
			
		case SKMsgTypeClientMarketingMessageUpdate2:
		{
			// Always ignored.
		}
			break;
			
		default:
			NSLog(@"Unhandled packet: Type=%u Body=%@", packet.msgType, packet.scanner.body);
			break;
	}
}


@end
