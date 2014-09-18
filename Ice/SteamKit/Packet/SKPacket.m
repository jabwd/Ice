//
//  SKPacket.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKPacket.h"

#define MAGIC_HEADER        0x31305456 // VS01
#define MAGIC_XOR			0xA426DF2B
#define HEADER_LENGTH		(4+2+4+4+4+4+4+4+4)

@implementation SKPacket

- (id)initWithDataString:(NSString *)dataString
{
	if( (self = [super init]) )
	{
		NSInteger bytes = (NSInteger)([dataString length]/2);
		NSMutableData *buffer = [[NSMutableData alloc] init];
		for(NSUInteger i = 0;i<bytes;i++)
		{
			NSString *byte = [dataString substringWithRange:NSMakeRange(i*2, 2)];
			char actualByte = (char)strtol([byte UTF8String], NULL, 16);
			[buffer appendBytes:&actualByte length:1];
		}
		_data = [buffer retain];
		[buffer release];
		[self scan];
	}
	return self;
}

- (id)initWithData:(NSData *)data
{
	if( (self = [super init]) )
	{
		_data = [data retain];
		[self scan];
	}
	return self;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_data		= nil;
		_newPacket	= true;
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

- (BOOL)isValid
{
	return NO;
}

- (void)scan
{
	NSMutableData *buff = [[NSMutableData alloc] initWithData:_data];
	
	// ignore the magic header
	[buff getBytes:&_len			range:NSMakeRange(0x04, 0x2)];
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
	
	[buff release];
}

- (NSData *)generate
{
	// The length included in the header should be of the data
	// that comes AFTER the header ( should be obv. )
	NSMutableData *finalBuffer	= [[NSMutableData alloc] init];
	_len = (UInt16)[_data length];
	UInt32 magicHeader			= 0x31305456;
	
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
	
	
	return [finalBuffer autorelease];
}

#pragma mark - Packet templates

+ (SKPacket *)connectPacket
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	packet.type				= 0x0001;
	packet.source			= 0x00000400;
	packet.destination		= 0x00000000;
	packet.sequenceNumber	= 0x00010000;
	packet.lastReceivedSeqNumber	= 0x00000000;
	packet.splitCount				= 0;
	packet.firstSeqNumber			= 0x0;
	packet.dataLength				= 0x0;
	
	return [packet autorelease];
}

+ (SKPacket *)connectChallengePacket:(NSData *)payload
{
	SKPacket *packet = [[SKPacket alloc] init];
	
	NSData *sub = [payload subdataWithRange:NSMakeRange(0x0, 0x4)];
	[[self class] transform:sub];
	
	packet.type				= 0x0403;
	packet.sequenceNumber	= 1;
	packet.destination		= 0x000000400;
	packet.source			= 0x0;
	packet.splitCount		= 1;
	packet.lastReceivedSeqNumber = 0;
	packet.firstSeqNumber	= 0;
	packet.dataLength		= 0;
	packet.data				= sub;
	
	return [packet autorelease];
}

#pragma mark - Some handy stuff

- (NSString *)description
{
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendFormat:@"[SKPacket type=%u ", _type];
	[str appendFormat:@"seq=%u ", _sequenceNumber];
	[str appendFormat:@"len=%u src=%u dst=%u payload=%@]", _len, _source, _destination, _data];
	return [str autorelease];
}

+ (void)transform:(NSData *)input
{
	char keyBytes[4] = {
		0xA4, 0x26, 0xDF, 0x2B
	};
	char *inputBytes = (char*)[input bytes];
	for(NSInteger i=0;i<4;i++)
	{
		unsigned char c = inputBytes[i] ^ keyBytes[i];
		inputBytes[i] = c;
	}
}

@end
