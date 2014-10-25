//
//  SKProtobufScanner.m
//  Ice
//
//  Created by Antwan van Houdt on 23/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufScanner.h"
#import "SKProtobufKey.h"
#import "NSData_SteamKitAdditions.h"
#import "NSMutableData_XfireAdditions.h"

NSUInteger const ProtoMask = 0x80000000;

@implementation SKProtobufScanner

- (id)initWithData:(NSData *)packetData
{
	if( (self = [super init]) )
	{
		_data	= [[NSData alloc] initWithData:packetData];
		_map	= [[NSMutableDictionary alloc] init];
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
	[_map release];
	_map = nil;
	[_header release];
	_header = nil;
	[super dealloc];
}

#pragma mark - Implementation Scanner

+ (void)swapBytes:(UInt8 *)bytes
{
	UInt8 buff = 0;
	
	buff = bytes[0];
	bytes[0] = bytes[3];
	bytes[3] = buff;
	buff = bytes[1];
	bytes[1] = bytes[2];
	bytes[2] = buff;
}

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
	while( [header length] > 0 )
	{
		const char byte = (const char)[header getByte];
		[header removeBytes:1];
		SKProtobufKey *key = [[SKProtobufKey alloc] initWithByte:&byte];
		[self scanValue:key data:header isHeader:YES];
		[key release];
	}
	
	NSLog(@"Final: %@", _header);
}

- (void)scanBody:(NSMutableData *)body
{
	while( [body length] > 0 )
	{
		const char byte = (const char)[body getByte];
		[body removeBytes:1];
		SKProtobufKey *key = [[SKProtobufKey alloc] initWithByte:&byte];
		[self scanValue:key data:body isHeader:NO];
		[key release];
	}
	
	NSLog(@"Final: %@", _map);
}

- (void)scanValue:(SKProtobufKey *)key data:(NSMutableData *)data isHeader:(BOOL)header
{
	NSMutableDictionary *storage = _map;
	if( header )
	{
		storage = _header;
	}
	
	switch(key.type)
	{
		case WireTypeVarint:
		{
			NSUInteger len = 0;
			UInt32 val = [self readVarint:data length:&len];
			if( len > 0 )
			{
				[storage setObject:[NSNumber numberWithInt:val]
						 forKey:key.valueKey];
				[data removeBytes:len];
			}
		}
			break;
			
		case WireTypeFixed:
		{
			UInt64 value = 0;
			[data getBytes:&value length:8];
			[storage setObject:[NSNumber numberWithLong:value]
					 forKey:key.valueKey];
			[data removeBytes:8];
		}
			break;
			
		case WireTypeFloat:
		{
			UInt32 value = 0;
			[data getBytes:&value length:4];
			[storage setObject:[NSNumber numberWithInt:value]
					 forKey:key.valueKey];
			[data removeBytes:4];
		}
			break;
			
		case WireTypePacked:
		{
			UInt32 length = (UInt32)[data getByte];
			[data removeBytes:1];
			if( length > 0 && [data length] >= length )
			{
				NSData *packetData = [data subdataWithRange:NSMakeRange(0, length)];
				[data removeBytes:length];
				NSString *str = [[NSString alloc] initWithData:packetData encoding:NSUTF8StringEncoding];
				if( str )
				{
					[storage setObject:str forKey:key.valueKey];
				}
				else
				{
					DLog(@"Unable to decode Protobuf packed string");
				}
			}
		}
			break;
			
		default:
			//DLog(@"Found unhandled value! %@ %@", key, data);
			//DLog(@"Unhandled key: %@", key);
			break;
	}
}

- (UInt32)readVarint:(NSData *)data length:(NSUInteger *)length
{
	UInt8 *bytes = (UInt8*)[data bytes];
	
	UInt32 value = 0;
	NSUInteger i= 0;
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

#pragma mark - Public class methods

- (void)loadMap:(NSString *)mapName
{
	NSString *path		= [[NSBundle mainBundle] pathForResource:mapName ofType:@"plist" inDirectory:@"Protobuf"];
	NSDictionary *map	= [[NSDictionary alloc] initWithContentsOfFile:path];
	if( map )
	{
		[_map release];
		_map = [[NSMutableDictionary alloc] initWithDictionary:map];
	}
	[map release];
}

- (WireType)typeAtFieldNumber:(NSUInteger)fieldNumber
{
	DLog(@"-this method should be removed");
	return -1;
}

- (id)valueForKey:(NSString *)key
{
	if( !_map )
	{
		NSLog(@"Error: cannot get valueForKey with protoscanner without loading a protobuf map");
		return nil;
	}
	NSString *fieldNumber		= _map[key];
	NSUInteger actualNumber		= [fieldNumber integerValue];
	if( actualNumber > 0 )
	{
		return [self valueForFieldNumber:actualNumber];
	}
	return nil;
}

- (id)valueForFieldNumber:(NSUInteger)fieldNumber
{
	if( fieldNumber >= [_values count] )
	{
		return nil;
	}
	return _values[fieldNumber];
}

@end
