//
//  SKProtobufValue.m
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufValue.h"
#import "NSData_SteamKitAdditions.h"

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
	[_data release];
	_data = nil;
	[super dealloc];
}


@end
