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
	
	// The rest of the data should be the protobuf packet body.
	[self scanBody:scanBuffer];
	
	[scanBuffer release];
}

- (void)scanHeader:(NSMutableData *)header
{
	while( [header length] > 0 )
	{
		// Read the SKProtobufKey which can be more
		// than just one byte.
		UInt32 length	= 0;
		UInt64 value	= [self readVarint:header length:&length];
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
	while( [body length] > 0 )
	{
		// Read the SKProtobufKey
		UInt32 length	= 0;
		UInt64 value = [self readVarint:body length:&length];
		[body removeBytes:length];
		
		// Scan the value, it will be automatically added to our body
		// content
		SKProtobufKey *key = [[SKProtobufKey alloc] initWithVarint:value];
		[self scanValue:key data:body isHeader:NO];
		[key release];
	}
}

- (NSArray *)scanRepeated:(NSData *)repeated
{
	NSMutableData *body		= [[NSMutableData alloc] initWithData:repeated];
	NSMutableArray *list	= [[NSMutableArray alloc] init];
	
	NSMutableDictionary *entry = [[NSMutableDictionary alloc] init];
	while( [body length] > 0 )
	{
		// Read the SKProtobufKey
		UInt32 length	= 0;
		UInt64 varint	= [self readVarint:body length:&length];
		[body removeBytes:length];
		
		// Scan the value, it will be automatically added to our body
		// content
		SKProtobufKey *key = [[SKProtobufKey alloc] initWithVarint:varint];
		SKProtobufValue *value = [[SKProtobufValue alloc] initWithData:body type:key.type];
		[body removeBytes:value.length];
		
		// Check if this key already exists, if it does
		// we most likely started on a new row!
		if( [entry objectForKey:key.valueKey] )
		{
			if( [entry count] > 0 )
			{
				[list addObject:entry];
			}
			[entry release];
			entry = [[NSMutableDictionary alloc] init];
		}
		
		if( value.value && ![key.valueKey isEqualToString:@"0"] )
		{
			entry[key.valueKey] = value.value;
		}
		
		[value release];
		[key release];
	}
	if( [entry count] > 0 )
	{
		[list addObject:entry];
	}
	[entry release];
	
	
	// Cleanup
	NSArray *result = [[NSArray alloc] initWithArray:list];
	[list release];
	[body release];
	
	return [result autorelease];
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
	if( value.value != nil )
	{
		id existing = storage[key.valueKey];
		if( existing )
		{
			if( [existing isKindOfClass:[NSMutableArray class]] )
			{
				[existing addObject:value.value];
			}
			else
			{
				NSMutableArray *list = [[NSMutableArray alloc] init];
				[list addObject:existing];
				[list addObject:value.value];
				[storage setObject:list forKey:key.valueKey];
				[list release];
			}
		}
		else
		{
			[storage setObject:value.value forKey:key.valueKey];
		}
	}
	else
	{
		//DLog(@"Unable to scan value for %@ %@ %@", key, self.body, self.header);
	}
	[data removeBytes:value.length];
	[value release];
}

- (UInt64)readVarint:(NSData *)data length:(UInt32 *)length
{
	UInt8 *bytes = (UInt8*)[data bytes];
	
	UInt8 i			= 0;
	UInt64 n		= 0;
	for(;i<[data length];i++)
	{
		UInt32 m = bytes[i];
		n = n + ((m & 0x7f) * pow(2,(7*i)));
		if( m < 128 )
		{
			++i; // for the length
			break;
		}
	}
	*length = i;
	
	return n;
}

@end
