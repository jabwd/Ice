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

#define HEADER_LENGTH		(4+2+4+4+4+4+4+4+4)
#define PACKET_MAX_SIZE		65507

NSInteger const SKPacketMinimumDataLength = 8; // was 36 before, but lets leave it at this for now.
NSInteger const SKPacketTCPMagicHeader = 0x31305456;
NSInteger const SKPacketUDPMagicHeader = 0x31305356;

UInt32 const SKlocalIPObfuscationMask	= 0xBAADF00D;
UInt32 const SKProtocolVersion			= 65579;
UInt32 const SKProtocolVersionMajorMask = 0xFFFF0000;
UInt32 const SKProtocolVersionMinorMask = 0xFFFF;

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
		packet.msgType = (type ^ 0x80000000);
	}
	else
	{
		packet.data = buff;
	}
	
	// If it is a protobuf packet we need to scan
	// the special protobuf packet layout and store it
	if( (type & 0x80000000) > 0 && packet.msgType != SKMsgTypeMulti )
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
	if( (self.msgType & 0x80000000) > 0 )
	{
		return YES;
	}
	return NO;
}

- (id)valueForKey:(NSString *)key
{
	return [_scanner valueForKey:key];
}

- (id)valueForFieldNumber:(NSUInteger)fieldNumber
{
	return nil;
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

+ (SKPacket *)logOnPacket:(NSString *)username password:(NSString *)password
				 language:(NSString *)language
{
	SKPacket *packet	= [[SKPacket alloc] init];
	SKMsgType type = 0x80000000 + SKMsgTypeClientLogon;
	packet.msgType = type;
	
	NSMutableData *data = [[NSMutableData alloc] init];
	[data appendBytes:&type length:4];
	
	SKProtobufCompiler *compiler = [[SKProtobufCompiler alloc] init];
	
	SKProtobufValue *v = [[SKProtobufValue alloc] initWithFixed64:76561197960265728];
	[compiler addHeaderValue:v forType:WireTypeFixed64 fieldNumber:1];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithVarint:65579];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:1];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithVarint:2047209998];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:2];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithVarint:1771];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:5];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithString:@"english"];
	[compiler addValue:v forType:WireTypePacked fieldNumber:6];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithVarint:SKOSTypeMacOS109];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:7];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithString:username];
	[compiler addValue:v forType:WireTypePacked fieldNumber:50];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithString:password];
	[compiler addValue:v forType:WireTypePacked fieldNumber:51];
	[v release];
	
	v	= [[SKProtobufValue alloc] initWithVarint:SKResultCodeFileNotFound];
	[compiler addValue:v forType:WireTypeVarint fieldNumber:82];
	[v release];
	
	[data appendData:[compiler generate]];
	
	/*v	= [[SKProtobufValue alloc] initWithString:@"STEAMGUARD"];
	key = [[SKProtobufKey alloc] initWithType:WireTypePacked fieldNumber:84];
	[compiler addValue:v forKey:key];
	*/
	
	packet.data = data;
	[data release];
	
	return [packet autorelease];
}

#pragma mark - Some handy stuff

- (NSString *)description
{
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendFormat:@"[SKPacket Msg=%u ", _msgType];
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
