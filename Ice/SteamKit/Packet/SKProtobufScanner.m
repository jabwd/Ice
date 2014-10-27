//
//  SKProtobufScanner.m
//  Ice
//
//  Created by Antwan van Houdt on 23/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufScanner.h"
#import "SKProtobufKey.h"
#import "SKProtobufValue.h"
#import "NSData_SteamKitAdditions.h"
#import "NSMutableData_XfireAdditions.h"

NSUInteger const ProtoMask = 0x80000000;

@implementation SKProtobufScanner

- (id)initWithData:(NSData *)packetData
{
	if( (self = [super init]) )
	{
		_data	= [[NSData alloc] initWithData:packetData];
		_body	= [[NSMutableDictionary alloc] init];
		_header = [[NSMutableDictionary alloc] init];
		
		if( [_data length] > 0 )
		{
			[self performScan];
		}
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	_data = nil;
	[_body release];
	_body = nil;
	[_header release];
	_header = nil;
	[super dealloc];
}

#pragma mark - Implementation Scanner

- (void)performScan
{
	NSMutableData *scanBuffer = [[NSMutableData alloc] initWithData:_data];
	[scanBuffer removeBytes:4]; // remove the MsgType
	UInt32 headerLength = [scanBuffer getUInt32];
	[scanBuffer removeBytes:4];
	
	// If there is a header present we will strip the data from scanBuffer
	// and attempt to scan the protobuf header
	if( headerLength > 0 && headerLength <= [scanBuffer length] )
	{
		NSMutableData *protoHeader = [[NSMutableData alloc]
							   initWithData:[scanBuffer subdataWithRange:NSMakeRange(0, headerLength)]];
		[scanBuffer removeBytes:headerLength];
		[self scanHeader:protoHeader];
		[protoHeader release];
	}
	else
	{
		DLog(@"No Protobuf header detected in scanned packet");
	}
	
	// The rest of the data should be the protobuf packet body.
	[self scanBody:scanBuffer];
	
	[scanBuffer release];
}

- (void)scanHeader:(NSMutableData *)header
{
	NSUInteger length	= 0;
	UInt32 value		= 0;
	while( [header length] > 0 )
	{
		// Read the SKProtobufKey which can be more
		// than just one byte.
		length	= 0;
		value	= 0;
		value	= [self readVarint:header length:&length];
		[header removeBytes:length];
		
		// Scan the value, it will be automatically added to our header
		// content
		SKProtobufKey *key = [[SKProtobufKey alloc] initWithVarint:value];
		[self scanValue:key data:header isHeader:YES];
		[key release];
	}
}

- (void)scanBody:(NSMutableData *)body
{
	NSUInteger length	= 0;
	UInt32 value		= 0;
	while( [body length] > 0 )
	{
		// Read the SKProtobufKey
		value	= 0;
		length	= 0;
		value	= [self readVarint:body length:&length];
		[body removeBytes:length];
		
		// Scan the value, it will be automatically added to our body
		// content
		SKProtobufKey *key = [[SKProtobufKey alloc] initWithVarint:value];
		[self scanValue:key data:body isHeader:NO];
		[key release];
	}
}

- (void)scanValue:(SKProtobufKey *)key data:(NSMutableData *)data isHeader:(BOOL)header
{
	// This is a quick way of deciding in what part
	// of the packet we will keep our data.
	NSMutableDictionary *storage = _body;
	if( header )
	{
		storage = _header;
	}
	
	SKProtobufValue *value = [[SKProtobufValue alloc] initWithData:data type:key.type];
	[storage setObject:value.value forKey:key.valueKey];
	[data removeBytes:value.length];
	[value release];
}

- (UInt32)readVarint:(NSData *)data length:(NSUInteger *)length
{
	UInt8 *bytes = (UInt8*)[data bytes];
	
	UInt32 value	= 0;
	NSUInteger i	= 0;
	for(;i<[data length];i++)
	{
		UInt8 b = bytes[i];
		value |= (b & 0x7F) << (7*i);
		
		*length = *length + 1;
		if( (b & 0x80) == 0 )
		{
			break; // End found.
		}
	}
	return value;
}

@end
