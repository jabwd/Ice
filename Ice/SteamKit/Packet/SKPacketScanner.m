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
#import "SKFriend.h"
#import "SKSteamID.h"

@implementation SKPacketScanner

- (id)initWithConnection:(SKConnection *)connection
{
	if( (self = [super init]) )
	{
		_connection		= [connection retain];
		_session		= [connection.session retain];
	}
	return self;
}

- (void)dealloc
{
	[_connection release];
	_connection = nil;
	[_session release];
	_session = nil;
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
			NSMutableData *buffer		= nil;
			
			// Uncompress the data if needed
			if( sizeUnzipped.unsignedIntegerValue > 0 )
			{
				buffer = [[data uncompressedDataWithSize:sizeUnzipped.intValue] retain];
			}
			else
			{
				buffer = [[NSMutableData alloc] initWithData:data];
			}
			
			// Scan the actual packets
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
			[_connection sendPacket:[SKPacket encryptionResponsePacket:_session.sessionKey]];
			break;
			
		case SKMsgTypeChannelEncryptResult:
			[_connection.session logIn];
			break;
			
		case SKMsgTypeClientLogOnResponse:
		{
			_session.rawSteamID = [packet.scanner.header[@"1"] unsignedIntegerValue];
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
					_session.sessionID = [[packet.scanner.header objectForKey:@"2"] unsignedIntValue];
					_session.keepAliveTimerSeconds = [[packet valueForFieldNumber:2] intValue];
					
					[_connection sendPacket:[SKPacket heartBeatPacket:_session]];
				}
					break;
					
				default:
					DLog(@"Unhandled login response: %@", packet.scanner.body);
					break;
			}
		}
			break;
			
		case SKMsgTypeClientLoggedOff:
		{
			SKResultCode resultCode = SKResultCodeInvalid;
			resultCode = [[packet valueForFieldNumber:1] unsignedIntValue];
			DLog(@"Received disconnect reason: %u", resultCode);
			[_session disconnectWithReason:resultCode];
		}
			break;
			
		case SKMsgTypeClientFriendsList:
			[self handleFriendsList:packet];
			break;
			
		case SKMsgTypeClientFriendsGroupsList:
			[self handleGroupsList:packet];
			break;
			
		case SKMsgTypeClientPersonaState:
			[self handlePersonaState:packet];
			break;
			
		case SKMsgTypeClientAccountInfo:
		{
			_session.currentUser.displayName = packet.scanner.body[@"1"];
			_session.currentUser.countryCode = packet.scanner.body[@"2"];
		}
			break;
			
		case SKMsgTypeClientEmailAddrInfo:
		{
			_session.currentUser.email = packet.scanner.body[@"1"];
		}
			break;
		
		case SKMsgTypeClientFriendMsgIncoming:
		{
			UInt64 remoteID			= [[packet valueForFieldNumber:1] unsignedIntegerValue];
			SKFriend *remoteFriend	= [_session friendForRawSteamID:remoteID];
			[remoteFriend receivedChatMessageWithBody:packet.scanner.body];
		}
			break;
		
		
			
		case SKMsgTypeClientSessionToken:
		{
			NSLog(@"=> Session Token received");
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
			
			_session.targetID	= [sourceID unsignedIntegerValue];
			
			[_session updateSentryFile:fileName data:data];
			SKPacket *packet = [SKPacket machineAuthResponsePacket:(UInt32)length.unsignedIntegerValue
														   session:_session];
			[_connection sendPacket:packet];
		}
			break;
			
		case SKMsgTypeClientNewLoginKey:
		{
			_session.loginKey	= packet.scanner.body[@"2"];
			_session.uniqueID	= [packet.scanner.body[@"1"] unsignedIntValue];
			[_connection sendPacket:[SKPacket loginKeyAccepted:_session]];
			[_session setStatus:SKSessionStatusConnected];
		}
			break;
			
		case SKMsgTypeClientServerList:
		{
			//DLog(@"Received a server list %@ %@", packet.scanner.body, packet.scanner.header);
		}
			break;
			
		case SKMsgTypeClientCMList:
		{
			//UInt32 IP	= [packet.scanner.body[@"1"] unsignedIntValue];
			//UInt32 port = [packet.scanner.body[@"2"] unsignedIntValue];
			//DLog(@"Server List: %u.%u.%u.%u:%u", ((IP >> 24) & 0xFF), ((IP >> 16) & 0xFF), ((IP >> 8) & 0xFF), (IP & 0xFF), port);
		}
			break;
		
		case SKMsgTypeClientWalletInfoUpdate:
		case SKMsgTypeClientPlayerNicknameList:
		case SKMsgTypeClientRequestedClientStats:
		case SKMsgTypeClientVACBanStatus:
		case SKMsgTypeClientServersAvailable:
		case SKMsgTypeClientIsLimitedAccount:
		case SKMsgTypeClientGameConnectTokens:
		case SKMsgTypeClientMarketingMessageUpdate2:
		case SKMsgTypeClientLicenseList:
		case SKMsgTypeClientUpdateGuestPassesList:
			break;
			
		default:
			DLog(@"Unhandled packet: %u\nBody %@\n Data: %@", packet.msgType, packet.scanner.body, packet.data);
			break;
	}
}

- (void)handlePersonaState:(SKPacket *)packet
{
	NSData *partial = [packet valueForFieldNumber:2];
	if( [partial length] > 0 )
	{
		NSArray *friends = [packet.scanner scanRepeated:partial];
		for(NSDictionary *rawFriend in friends)
		{
			[_session updateFriend:rawFriend];
		}
	}
}

- (void)handleGroupsList:(SKPacket *)packet
{
	
}

- (void)handleFriendsList:(SKPacket *)packet
{
	NSDictionary *list	= packet.scanner.body;
	id value			= list[@"2"];
	
	// The list is either NSData or an NSArray depending
	// on the amount of friends
	NSArray *friendsList = (NSArray *)value;
	if( [value isKindOfClass:[NSData class]] )
	{
		friendsList = @[value];
	}
	
	for(NSData *friend in friendsList)
	{
		if( ![friend isKindOfClass:[NSData class]] )
		{
			DLog(@"Error in friends list: %@", friendsList);
			continue;
		}
		NSDictionary *remoteFriend = [packet.scanner scanRepeated:friend][0];
		SKFriendRelationType type = [remoteFriend[@"2"] unsignedIntValue];
		SKFriend *friend	= [[SKFriend alloc] initWithRawSteamID:[remoteFriend[@"1"] unsignedIntegerValue]];
		if( type == SKFriendRelationTypeFriend )
		{
			[_connection.session connectionAddFriend:friend];
		}
		else if( type == SKFriendRelationTypeRequestInitiator )
		{
			NSLog(@"Received a friend request: %@", friend);
			[_connection.session addPendingFriend:friend];
		}
		else if( type == SKFriendRelationTypeNone )
		{
			NSLog(@"Friend removed: %@", friend);
		}
		[friend release];
	}
	[_connection.session sortFriendsList];
}


@end
