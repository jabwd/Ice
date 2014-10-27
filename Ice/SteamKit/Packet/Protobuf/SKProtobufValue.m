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
		NSData *numberData		= [[NSData dataWithBytes:&varint length:8] dataByTruncatingUselessData];
		const char *bytes		= [numberData bytes];
		char bitBuffer			= 0;
		
		NSLog(@"%@", numberData);
		
		char bits[64];
		char final[8];
		char bitIdx			= 0;
		char finalIdx		= 0;
		for(UInt8 i = 0;i<[numberData length];i++)
		{
			// Create a bit stream
			char b = bytes[i];
			for(UInt8 r = 0;r<8;r++)
			{
				char bit = ((b >> (7-r)) & 0x1);
				bits[bitIdx] = bit;
				bitIdx++;
			}
		}
		
		/*for(UInt8 r = 0;r<bitIdx;r++)
		{
			char bit = bits[r];
			
			if( (finalIdx == 0) && (bitIdx-r) > 7 )
			{
				final[0] = 1;
				finalIdx++;
				DLog(@"Inserting msb at %u", r);
			}
			final[finalIdx] = bit;
			finalIdx++;
			
			if( finalIdx == 7 )
			{
				char byte = 0;
				byte |= (final[0] << 7);
				byte |= (final[1] << 6);
				byte |= (final[2] << 5);
				byte |= (final[3] << 4);
				byte |= (final[4] << 3);
				byte |= (final[5] << 2);
				byte |= (final[6] << 1);
				byte |= (final[7] << 0);
				[buff appendBytes:&byte length:1];
				finalIdx = 0;
			}
		}*/
		
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
