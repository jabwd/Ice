//
//  SKProtobufValue.m
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufValue.h"

@implementation SKProtobufValue

- (id)initWithData:(NSData *)data type:(WireType)type
{
	if( (self = [super init]) )
	{
		
	}
	return self;
}

- (id)initWithVarint:(UInt64)varint
{
	if( (self = [super init]) )
	{
		_type = WireTypeVarint;
		
		/*UInt8 *bytes = (UInt8 *)malloc(8);
		
		bytes[0] = (varint & 0xFF00000000000000);
		bytes[1] = (varint & 0x00FF00000000000000);
		bytes[2] = (varint & 0x00FF00000000000000);
		bytes[3] = (varint & 0x00FF00000000000000);
		bytes[4] = (varint & 0x00FF00000000000000);
		bytes[5] = (varint & 0x00FF00000000000000);
		bytes[6] = (varint & 0x00FF00000000000000);
		bytes[7] = (varint & 0x00FF00000000000000);
		
		// Cleanup
		free(bytes);
		
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
		}*/
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
	[_data release];
	_data = nil;
	[super dealloc];
}


@end
