//
//  SKPacket.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKPacket.h"
#import <zlib.h>
#import "SKRSAEncryption.h"
#import "SKAESEncryption.h"
#import "SKSession.h"
#import "SKProtobufScanner.h"
#import "SteamConstants.h"
#import "SKProtobufCompiler.h"
#import "SKProtobufKey.h"
#import "SKProtobufValue.h"
#import "NSData_SteamKitAdditions.h"
#import "SKSentryFile.h"
#import "SKSteamID.h"
#import "SKFriend.h"
#import "SKProtobufEncoder.h"

NSInteger const SKPacketTCPMagicHeader = 0x31305456;
NSInteger const SKPacketUDPMagicHeader = 0x31305356;

UInt32 const SKlocalIPObfuscationMask	= 0xBAADF00D;
UInt32 const SKProtocolVersion			= 65579;
UInt32 const SKProtocolVersionMajorMask = 0xFFFF0000;
UInt32 const SKProtocolVersionMinorMask = 0xFFFF;
UInt32 const SKProtocolProtobufMask		= 0x80000000;

@implementation SKPacket

+ (SKPacket *)packetByDecodingTCPBuffer:(NSData *)buffer sessionKey:(NSData *)sessionKey error:(NSError **)error
{
	NSMutableData *buff = [[NSMutableData alloc] initWithData:buffer];
	SKPacket *packet = [[SKPacket alloc] init];
	
	SKMsgType type = SKMsgTypeInvalid;
	[buff getBytes:&type range:NSMakeRange(0x0, 0x04)];
	packet.msgType = type;
	
	if( type != SKMsgTypeChannelEncryptRequest && type != SKMsgTypeChannelEncryptResult )
	{
		// idk what else.
		// buff is encrypted data, we need to decrypt it.
		if( sessionKey )
		{
			packet.data = [SKAESEncryption decryptPacketData:buff key:sessionKey];
		}
		else
		{
			packet.data = buff;
		}
		[packet.data getBytes:&type length:4];
		packet.msgType = (type & 0x7FFFFFFF);
	}
	else
	{
		packet.data = buff;
	}
	
	// If it is a protobuf packet we need to scan
	// the special protobuf packet layout and store it
	if( (type & 0x80000000) > 0 )
	{
		packet.scanner = [[[SKProtobufScanner alloc] initWithData:packet.data] autorelease];
	}
	
	[buff release];
	return [packet autorelease];
}

+ (SKPacket *)packetByDecodingUDPBuffer:(NSData *)buffer error:(NSError **)error
{
	return nil;
}

- (void)dealloc
{
	[_data release];
	_data = nil;
	[_raw release];
	_raw = nil;
	[_scanner release];
	_scanner = nil;
	[super dealloc];
}

#pragma mark -

- (NSData *)getRaw
{
	if( _raw == nil )
	{
		_raw = [[self generate] retain];
	}
	return _raw;
}

- (NSData *)generate
{
	// The length included in the header should be of the data
	// that comes AFTER the header but haven't actually confirmed this yet
	// Update: Either dataLength or Length is the leng on the entire series
	// and the other one on just the data in the current packet, which is which
	// seems obvious but should be researched regardless.
	NSMutableData *finalBuffer	= [[NSMutableData alloc] init];
	UInt32 header = SKPacketTCPMagicHeader;
	UInt32 len = (UInt32)[_data length];
	[finalBuffer appendBytes:&len length:4];
	[finalBuffer appendBytes:&header length:4];
	[finalBuffer appendData:_data];
	
	return [finalBuffer autorelease];
}

- (BOOL)isProtobufPacket
{
	if( (self.msgType & SKProtocolProtobufMask) > 0 )
	{
		return YES;
	}
	return NO;
}

- (id)valueForKey:(NSString *)key
{
	return _scanner.body[key];
}

- (id)valueForFieldNumber:(NSUInteger)fieldNumber
{
	return _scanner.body[[NSString stringWithFormat:@"%lu", fieldNumber]];
}

#pragma mark - Packet templates

+ (SKPacket *)encryptionResponsePacket:(NSData *)sessionKey
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	NSString *randomPadding = @"18050000 ffffffffffffffffffffffffffffffff 01000000 80000000";
	NSMutableData *payLoad = [[NSMutableData alloc] init];
	[payLoad appendData:[NSData dataFromByteString:randomPadding]];
	NSData *encryptedKey = [SKRSAEncryption encryptData:sessionKey];
	[payLoad appendData:encryptedKey];
	UInt32 crc = (UInt32)crc32(0, [encryptedKey bytes], (unsigned int)[encryptedKey length]);
	[payLoad appendBytes:&crc length:4];
	UInt32 len = 0;
	[payLoad appendBytes:&len length:4];
	packet.data = payLoad;
	[payLoad release];
	
	
	return [packet autorelease];
}

+ (SKPacket *)logOnPacket:(SKSession *)session
				 language:(NSString *)language
{
	NSString *guardCode = [session steamGuard];
	
	SKPacket *packet	= [[SKPacket alloc] init];
	SKMsgType type = SKProtocolProtobufMask + SKMsgTypeClientLogon;
	packet.msgType = type;
	
	NSMutableData *data = [[NSMutableData alloc] init];
	[data appendBytes:&type length:4];
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:1];
	[v release];
	
	[compiler addVarint:SKProtocolVersion field:1];
	[compiler addVarint:2964189448 field:2];
	[compiler addVarint:1771 field:5];
	
	v	= [[SKProtobufValue alloc] initWithString:@"english"];
	[compiler addValue:v forType:WireTypePacked fieldNumber:6];
	[v release];
	
	[compiler addVarint:SKOSTypeMacOS1010 field:7];
	
	v	= [[SKProtobufValue alloc] initWithString:[session username]];
	[compiler addValue:v forType:WireTypePacked fieldNumber:50];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithString:[session password]];
	[compiler addValue:v forType:WireTypePacked fieldNumber:51];
	[v release];
	
	SKSentryFile *file = [[SKSentryFile alloc] initWithSession:session];
	NSData *hash = [file sha1Hash];
	SKResultCode sentryResult = SKResultCodeFileNotFound;
	if( [hash length] > 0 && [guardCode length] < 1 )
	{
		sentryResult = SKResultCodeOK;
		
		v = [[SKProtobufValue alloc] initWithPackedData:hash];
		[compiler addValue:v forType:WireTypePacked fieldNumber:83];
		[v release];
	}
	
	[compiler addVarint:sentryResult field:82];
	
	[file release];
	
	if( guardCode && [guardCode length] > 3 )
	{
		v	= [[SKProtobufValue alloc] initWithString:guardCode];
		[compiler addValue:v forType:WireTypePacked fieldNumber:84];
		[v release];
	}
	
	[data appendData:[compiler generate]];
	packet.data = data;
	[packet encryptWithSession:session];
	[data release];
	[compiler release];
	
	return [packet autorelease];
}

+ (SKPacket *)loginKeyAccepted:(SKSession *)session
{
	SKPacket *packet = [[SKPacket alloc] init];
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientNewLoginKeyAccepted;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// Generate the header
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithFixed64:session.targetID];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:11];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v forType:WireTypeVarint fieldNumber:2];
	[v release];
	
	// Generate the body
	v = [[SKProtobufValue alloc] initWithVarint:session.uniqueID];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:1];
	[v release];
	
	// Generate the packet itself ID + payload
	SKMsgType type = packet.msgType;
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[buffer release];
	[compiler release];
	
	return [packet autorelease];
}

+ (SKPacket *)machineAuthResponsePacket:(UInt32)length
								session:(SKSession *)session
{
	SKPacket *packet = [[SKPacket alloc] init];
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientUpdateMachineAuthResponse;
	
	NSMutableData *buffer			= [[NSMutableData alloc] init];
	SKProtobufCompiler *compiler	= [[SKProtobufCompiler alloc] init];
	SKSentryFile *sentryFile		= [[SKSentryFile alloc] initWithSession:session];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithFixed64:session.targetID];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:11];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v forType:WireTypeVarint fieldNumber:2];
	[v release];
	
	// + Generate the body + //
	v = [[SKProtobufValue alloc] initWithString:[sentryFile fileName]];
	[compiler addValue:v forType:WireTypePacked fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:SKResultCodeOK];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:2];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:length];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:3];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithPackedData:[sentryFile sha1Hash]];
	[compiler addValue:v forType:WireTypePacked fieldNumber:4];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:length];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:7];
	[v release];
	
	SKMsgType type = packet.msgType;
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	
	// Cleanup
	[compiler		release];
	[buffer			release];
	[sentryFile		release];
	
	return [packet autorelease];
}

+ (SKPacket *)heartBeatPacket:(SKSession *)session
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientHeartBeat;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v forType:WireTypeVarint fieldNumber:2];
	[v release];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)requestUserProfilePacket:(SKSession *)session rawSteamID:(UInt64)steamID
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientFriendProfileInfo;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithFixed64:steamID];
	[compiler addValue:v fieldNumber:1];
	[v release];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)changeUserStatusPacket:(SKSession *)session
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientChangeStatus;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	
	// New status
	[compiler addVarint:session.userStatus field:1];
	
	[compiler addData:[SKProtobufEncoder encodeString:session.currentUser.displayName]
			  forType:WireTypePacked fieldNumber:2];
	
	// User set
	if( session.userStatus == SKPersonaStateAway ||
	    session.userStatus == SKPersonaStateSnooze )
	{
		//[compiler addVarint:0 field:5];
	}
	else
	{
		[compiler addVarint:1 field:5];
	}
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)sendMessagePacket:(NSString *)message
						 friend:(SKFriend *)remoteFriend
						session:(SKSession *)session
						   type:(SKChatEntryType)entryType
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientFriendMsg;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	
	// Remote ID
	[compiler addData:[SKProtobufEncoder encodeFixed64:remoteFriend.steamID.rawSteamID] forType:WireTypeFixed64 fieldNumber:1];
	
	// Entry type
	[compiler addVarint:entryType field:2];
	[compiler addData:[SKProtobufEncoder encodeString:message] forType:WireTypePacked fieldNumber:3];
	[compiler addData:[SKProtobufEncoder encodeFixed32:(UInt32)[[NSDate date] timeIntervalSince1970]] forType:WireTypeFixed32 fieldNumber:4];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)requestFriendProfilePacket:(SKFriend *)remoteFriend
{
	SKSession *session = remoteFriend.session;
	if( !session )
	{
		return nil;
	}
	
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientFriendMsg;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	
	// + Create the body + //
	v = [[SKProtobufValue alloc] initWithFixed64:remoteFriend.steamID.rawSteamID];
	[compiler addValue:v fieldNumber:1];
	[v release];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	NSLog(@"Sending: %@", buffer);
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)addFriendPacket:(SKFriend *)remoteFriend
{
	SKSession *session = nil;
	session = remoteFriend.session;
	if( !session )
	{
		DLog(@"[Error] cannot send requestFriendsData packet with a proper session");
		return nil;
	}
	
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientAddFriend;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	// -------------------//
	
	[compiler addData:[SKProtobufEncoder encodeFixed64:remoteFriend.steamID.rawSteamID] forType:WireTypeFixed64 fieldNumber:1];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)removeFriendPacket:(SKFriend *)remoteFriend
{
	SKSession *session = nil;
	session = remoteFriend.session;
	if( !session )
	{
		DLog(@"[Error] cannot send requestFriendsData packet with a proper session");
		return nil;
	}
	
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientRemoveFriend;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	// -------------------//
	
	[compiler addData:[SKProtobufEncoder encodeFixed64:remoteFriend.steamID.rawSteamID] forType:WireTypeFixed64 fieldNumber:1];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)requestFriendsDataPacket:(NSArray *)friends flag:(SKPersonaStateFlag)flag
{
	if( [friends count] == 0 )
	{
		return nil;
	}
	SKSession *session = nil;
	session = [friends[0] session];
	if( !session )
	{
		DLog(@"[Error] cannot send requestFriendsData packet with a proper session");
		return nil;
	}
	
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientRequestFriendData;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	// -------------------//
	
	// Requested persona state
	v = [[SKProtobufValue alloc] initWithVarint:flag];
	[compiler addValue:v fieldNumber:1];
	[v release];
	
	for(SKFriend *remoteFriend in friends)
	{
		v = [[SKProtobufValue alloc] initWithFixed64:remoteFriend.steamID.rawSteamID];
		[compiler addValue:v fieldNumber:2];
		[v release];
	}
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)requestFriendDataPacket:(SKFriend *)remoteFriend flag:(SKPersonaStateFlag)flag
{
	SKSession *session = nil;
	session = remoteFriend.session;
	if( !session )
	{
		DLog(@"[Error] cannot send requestFriendsData packet with a proper session");
		return nil;
	}
	
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientRequestFriendData;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler	= [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer			= [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	// -------------------//
	
	// Requested persona state
	[compiler addVarint:flag field:1];
	[compiler addFixed64:remoteFriend.steamID.rawSteamID field:2];
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

+ (SKPacket *)requestAppInfoPacket:(UInt32)appID session:(SKSession *)session
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.msgType = SKProtocolProtobufMask + SKMsgTypeClientAppInfoRequest;
	SKMsgType type = packet.msgType;
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	// + Create the header + //
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:session.rawSteamID];
	[compiler addHeaderValue:v fieldNumber:1];
	[v release];
	
	v = [[SKProtobufValue alloc] initWithVarint:session.sessionID];
	[compiler addHeaderValue:v fieldNumber:2];
	[v release];
	// -------------------//
	
	NSMutableData *buff = [[NSMutableData alloc] init];
	SKProtobufKey *key = [[SKProtobufKey alloc] initWithType:WireTypeVarint fieldNumber:1];
	[buff appendData:[key encode]];
	[key release];
	[buff appendData:[SKProtobufEncoder encodeVarint:appID]];
	NSData *dat = [SKProtobufEncoder encodeVarint:0xFFFF];
	UInt32 flags = 0xFFFF;
	UInt32 crc = (UInt32)crc32(0, (void *)&flags, 4);
	key = [[SKProtobufKey alloc] initWithType:WireTypeVarint fieldNumber:2];
	[buff appendData:[key encode]];
	[buff appendData:dat];
	[key release];
	key = [[SKProtobufKey alloc] initWithType:WireTypeVarint fieldNumber:3];
	[buff appendData:[key encode]];
	[key release];
	[buff appendData:[SKProtobufEncoder encodeVarint:crc]];
	[compiler addData:[SKProtobufEncoder encodeData:buff] forType:WireTypePacked fieldNumber:1];
	[buff release];
	
	
	[buffer appendBytes:&type length:4];
	[buffer appendData:[compiler generate]];
	
	packet.data = buffer;
	[packet encryptWithSession:session];
	[compiler release];
	[buffer release];
	
	return [packet autorelease];
}

#pragma mark - Some handy stuff

- (void)encryptWithSession:(SKSession *)session
{
	NSData *final = [SKAESEncryption encryptPacketData:self.data key:session.sessionKey];
	self.data = final;
}

- (NSString *)description
{
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendFormat:@"[SKPacket Msg=%u ", (_msgType & 0x7FFFFFFF)];
	[str appendFormat:@"data=%@", _data];
	[str appendFormat:@" length=%lu]", [_data length]];
	return [str autorelease];
}

+ (void)transform:(NSData *)input
{
	char keyBytes[4] = {
		0x2B, 0xDF, 0x26, 0xA4
	};
	char *inputBytes = (char*)[input bytes];
	for(NSInteger i=0;i<4;i++)
	{
		unsigned char c = inputBytes[i] ^ keyBytes[i];
		inputBytes[i] = c;
	}
}

@end
