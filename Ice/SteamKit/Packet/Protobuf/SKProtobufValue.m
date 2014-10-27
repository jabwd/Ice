//
//  SKProtobufValue.m
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufValue.h"
#import "SKProtobufKey.h"
#import "NSData_SteamKitAdditions.h"

@implementation SKProtobufValue

- (id)initWithData:(NSData *)data type:(WireType)type
{
	if( (self = [super init]) )
	{
		_type = type;
		DLog(@"Scanning %u", type);
		switch( type )
		{
			case WireTypeVarint:
			{
				NSUInteger len = 0;
				UInt64 val = [self readVarint:data length:&len];
				_value = [[NSNumber alloc] initWithInteger:val];
				_data = [[data subdataWithRange:NSMakeRange(0, len)] retain];
			}
				break;
				
			case WireTypeFixed64:
			{
				UInt64 value = 0;
				[data getBytes:&value length:8];
				_value	= [[NSNumber alloc] initWithInteger:value];
				_data	= [[data subdataWithRange:NSMakeRange(0, 8)] retain];
			}
				break;
				
			case WireTypeFixed32:
			{
				UInt32 value = 0;
				[data getBytes:&value length:4];
				_value	= [[NSNumber alloc] initWithInteger:value];
				_data	= [[data subdataWithRange:NSMakeRange(0, 4)] retain];
			}
				break;
				
			case WireTypePacked:
			{
				UInt32 length = (UInt32)[data getByte];
				if( length > 0 && [data length] >= length )
				{
					NSData *packetData = [data subdataWithRange:NSMakeRange(1, length)];
					NSString *str = [[NSString alloc] initWithData:packetData encoding:NSUTF8StringEncoding];
					if( str )
					{
						_value	= [str retain];
						_data	= [[data subdataWithRange:NSMakeRange(0, length+1)] retain];
					}
					else
					{
						DLog(@"Unable to decode Protobuf packed string");
					}
					[str release];
				}
			}
				break;
				
			default:
				DLog(@"Found unhandled value! %u %@", type, data);
				_value	= nil;
				_data	= [data retain];
				break;
		}
	}
	return self;
}

- (id)initWithVarint:(UInt64)varint
{
	if( (self = [super init]) )
	{
		_type = WireTypeVarint;
		
		NSMutableData *buff		= [[NSMutableData alloc] init];
		
		UInt64 n = varint;
		do {
			UInt8 tmp		= (UInt8)(n % 0x80);
			UInt64 next		= (UInt64)floor(n/0x80);
			if( next != 0 )
			{
				tmp = tmp + 0x80;
			}
			[buff appendBytes:&tmp length:1];
			n = next;
		} while( n != 0 );
		
		_data = [buff retain];
		
		// Cleanup
		[buff release];
	}
	return self;
}

- (id)initWithFixed64:(UInt64)fixed64
{
	if( (self = [super init]) )
	{
		_type = WireTypeFixed64;
		
		_data = [[NSData alloc] initWithBytes:&fixed64 length:8];
	}
	return self;
}

- (id)initWithFixed32:(UInt32)fixed32
{
	if( (self = [super init]) )
	{
		_type = WireTypeFixed64;
		
		_data = [[NSData alloc] initWithBytes:&fixed32 length:4];
	}
	return self;
}

- (id)initWithString:(NSString *)string
{
	if( (self = [super init]) )
	{
		_type = WireTypePacked;
		
		NSMutableData *buff = [[NSMutableData alloc] init];
		
		// Generate the length byte and append it
		UInt8 length = (UInt8)[string length];
		if( length == 0xFF )
		{
			DLog(@"String for protobuf compiler probably too long!");
		}
		[buff appendBytes:&length length:1];
		
		// Append the string data
		[buff appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
		
		_data = [buff retain];
		
		// Cleanup
		[buff release];
	}
	return self;
}

- (void)dealloc
{
	[_value release];
	_value = nil;
	[_data release];
	_data = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (NSUInteger)length
{
	return [_data length];
}

- (UInt64)readVarint:(NSData *)data length:(NSUInteger *)length
{
	UInt8 *bytes = (UInt8*)[data bytes];
	
	UInt64 value	= 0;
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
