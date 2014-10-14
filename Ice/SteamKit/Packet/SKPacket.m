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
#import "NSData_XfireAdditions.h"

#define UDP_HEADER			0x31305356 // VS01
#define TCP_HEADER			0x31305456 // VT01
#define HEADER_LENGTH		(4+2+4+4+4+4+4+4+4)
#define PACKET_MAX_SIZE		65507

//NSInteger const SKPacketMinimumDataLength = 36;
NSInteger const SKPacketMinimumDataLength = 8;

@implementation SKPacket

- (id)initWithDataString:(NSString *)dataString
{
	if( (self = [super init]) )
	{
		_data = [[NSData dataFromByteString:dataString] retain];
		[self scan:nil];
	}
	return self;
}

- (id)initWithData:(NSData *)data
{
	if( (self = [super init]) )
	{
		_data = [data retain];
		[self scan:nil];
	}
	return self;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_data		= nil;
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	_data = nil;
	[super dealloc];
}

#pragma mark -

- (BOOL)scan:(NSError *)error
{
	NSMutableData *buff = [[NSMutableData alloc] initWithData:_data];
	
	UInt32 packetStart = 0;
	UInt32 secondStart = 0;
	[buff getBytes:&packetStart length:sizeof(UInt32)];
	[buff getBytes:&secondStart range:NSMakeRange(0x04, sizeof(UInt32))];
	
	if( packetStart == UDP_HEADER )
	{
		//[buff getBytes:&_len			range:NSMakeRange(0x04, 0x2)];
		_len = (UInt16)secondStart;
		[buff getBytes:&_type			range:NSMakeRange(0x06, 0x2)];
		[buff getBytes:&_source			range:NSMakeRange(0x08, 0x4)];
		[buff getBytes:&_destination	range:NSMakeRange(0x0C, 0x4)];
		[buff getBytes:&_sequenceNumber range:NSMakeRange(0x10, 0x4)];
		[buff getBytes:&_lastReceivedSeqNumber range:NSMakeRange(0x14, 0x4)];
		[buff getBytes:&_splitCount		range:NSMakeRange(0x18, 0x4)];
		[buff getBytes:&_firstSeqNumber range:NSMakeRange(0x1C, 0x4)];
		[buff getBytes:&_dataLength		range:NSMakeRange(0x20, 0x04)];
		
		[_data release];
		_data = [[buff subdataWithRange:NSMakeRange(0x24, _len)] retain];
	}
	else if( secondStart == TCP_HEADER )
	{
		// Should be a TCP packet, verify:
		DLog(@"Found a TCP packet");
		[_data release];
		_data = [[buff subdataWithRange:NSMakeRange(0x08, packetStart)] retain];
		NSData *dataString = [NSData dataFromByteString:@"17050000 ffffffff ffffffff ffffffff ffffffff 01000000 01000000"];
		if( [_data isEqualToData:dataString] )
		{
			_type = SKPacketTypeEncryptionRequest;
		}
	}
	
	[buff release];
	return YES;
}

- (NSData *)generate
{
	// The length included in the header should be of the data
	// that comes AFTER the header but haven't actually confirmed this yet
	// Update: Either dataLength or Length is the leng on the entire series
	// and the other one on just the data in the current packet, which is which
	// seems obvious but should be researched regardless.
	NSMutableData *finalBuffer	= [[NSMutableData alloc] init];
	_len = (UInt16)[_data length];
	if( !_isTCP )
	{
		UInt32 magicHeader			= 0x31305356;
		
		// Generate the packet header
		[finalBuffer appendBytes:&magicHeader	length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_len			length:sizeof(UInt16)];
		[finalBuffer appendBytes:&_type			length:sizeof(UInt16)];
		[finalBuffer appendBytes:&_source		length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_destination	length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_sequenceNumber			length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_lastReceivedSeqNumber	length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_splitCount		length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_firstSeqNumber	length:sizeof(UInt32)];
		[finalBuffer appendBytes:&_dataLength		length:sizeof(UInt32)];
		
		// Finally append the payload
		if( [_data length] > 0 )
		{
			[finalBuffer appendData:_data];
		}
	}
	else
	{
		UInt32 header = TCP_HEADER;
		UInt32 len = (UInt32)[_data length];
		[finalBuffer appendBytes:&len length:4];
		[finalBuffer appendBytes:&header length:4];
		[finalBuffer appendData:_data];
	}
	
	return [finalBuffer autorelease];
}

#pragma mark - Packet templates

+ (SKPacket *)connectPacket
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.type				= SKPacketTypeConnectBegin;
	packet.source			= 1;
	packet.destination		= 0;
	packet.sequenceNumber	= 1;
	packet.lastReceivedSeqNumber	= 0;
	packet.splitCount				= 0;
	packet.firstSeqNumber			= 0;
	packet.dataLength				= 0;
	
	return [packet autorelease];
}

+ (SKPacket *)connectChallengePacket:(NSData *)payload
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	NSData *sub = [payload subdataWithRange:NSMakeRange(0x0, 0x4)];
	[[self class] transform:sub];
	
	packet.type						= SKPacketTypeConnectChallengeResponse;
	packet.sequenceNumber			= 1;
	packet.destination				= 0;
	packet.source					= 1;
	packet.splitCount				= 1;
	packet.lastReceivedSeqNumber	= 1;
	packet.firstSeqNumber			= 1;
	packet.dataLength				= 4;
	packet.data						= sub;
	
	return [packet autorelease];
}

+ (SKPacket *)encryptionResponsePacket:(NSData *)sessionKey tcp:(BOOL)isTCP
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	if( isTCP )
	{
		packet.isTCP = true;
	}
	
	packet.type						= SKPacketTypeEncryptionResponse;
	packet.sequenceNumber			= 2;
	packet.lastReceivedSeqNumber	= 3;
	packet.source					= 1;
	
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
	packet.dataLength = (UInt32)[payLoad length];
	packet.splitCount = 1;
	packet.firstSeqNumber = packet.sequenceNumber;
	[payLoad release];
	return [packet autorelease];
}

#pragma mark - Some handy stuff

- (NSData *)iv
{
	NSData *packetData = [self generate];
	return [packetData subdataWithRange:NSMakeRange(0, 16)];
}

- (NSString *)description
{
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendFormat:@"[SKPacket type=%u ", _type];
	[str appendFormat:@"seq=%u ", _sequenceNumber];
	[str appendFormat:@"len=%u src=%u dst=%u payload=%@", _len, _source, _destination, _data];
	[str appendFormat:@" recv=%u split=%u dLen=%u first=%u]", _lastReceivedSeqNumber, _splitCount, _dataLength, _firstSeqNumber];
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
