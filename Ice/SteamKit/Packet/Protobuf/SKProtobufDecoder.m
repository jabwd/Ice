//
//  SKProtobufDecoder.m
//  Ice
//
//  Created by Antwan van Houdt on 23/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufDecoder.h"
#import "SKProtobufConstants.h"

@implementation SKProtobufDecoder

+ (id)valueForData:(NSData *)data wireType:(WireType)type length:(UInt32 *)length
{
	switch( type )
	{
		case WireTypeVarint:
		{
			NSUInteger len = 0;
			UInt64 val = [self readVarint:data length:&len];
			*length = (UInt32)val;
			return [[[NSNumber alloc] initWithUnsignedInteger:val] autorelease];
		}
			break;
			
		case WireTypeFixed64:
		{
			UInt64 value = 0;
			[data getBytes:&value length:8];
			*length = 8;
			return [[[NSNumber alloc] initWithUnsignedInteger:value] autorelease];
		}
			break;
			
		case WireTypeFixed32:
		{
			UInt32 value = 0;
			[data getBytes:&value length:4];
			*length = 4;
			return [[[NSNumber alloc] initWithUnsignedInteger:value] autorelease];
		}
			break;
			
		case WireTypePacked:
		{
			NSUInteger varintSize = 0;
			UInt64 len = [self readVarint:data length:&varintSize];
			if( len > 0 && [data length] >= len )
			{
				NSData *packetData = [data subdataWithRange:NSMakeRange(varintSize, len)];
				NSString *str = [[NSString alloc] initWithData:packetData encoding:NSUTF8StringEncoding];
				*length = (UInt32)(len+varintSize);
				if( str )
				{
					return [str autorelease];
				}
				else if( [packetData length] > 0 )
				{
					return packetData;
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
			*length = (UInt32)[data length];
			return nil;
			break;
	}
	return nil;
}

+ (UInt64)readVarint:(NSData *)data length:(NSUInteger *)length
{
	UInt8 *bytes = (UInt8*)[data bytes];
	
	UInt8 i	= 0;
	UInt64 n		= 0;
	for(;i<[data length];i++)
	{
		UInt32 m = bytes[i];
		n = n + ((m & 0x7f) * pow(2,(7*i)));
		if( m < 128 )
		{
			++i;
			break;
		}
	}
	*length = i;
	
	return n;
}

@end
