//
//  SKProtobufEncoder.m
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufEncoder.h"

@implementation SKProtobufEncoder

+ (NSData *)encodeVarint:(UInt64)value
{
	NSMutableData *buff		= [[NSMutableData alloc] init];
	
	UInt64 n = value;
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
	
	return [buff autorelease];
}

+ (NSData *)encodeFixed64:(UInt64)fixedValue
{
	return [[[NSData alloc] initWithBytes:&fixedValue length:sizeof(UInt64)] autorelease];
}

+ (NSData *)encodeFixed32:(UInt32)fixedValue
{
	return [[[NSData alloc] initWithBytes:&fixedValue length:sizeof(UInt32)] autorelease];
}

+ (NSData *)encodeString:(NSString *)stringValue
{
	NSMutableData *buff = [[NSMutableData alloc] init];
	NSData *strData		= [stringValue dataUsingEncoding:NSUTF8StringEncoding];
	
	[buff appendData:[SKProtobufEncoder encodeVarint:[strData length]]];
	[buff appendData:strData];
	
	return [buff autorelease];
}

+ (NSData *)encodeData:(NSData *)packed
{
	NSMutableData *buffer = [[NSMutableData alloc] init];
	
	[buffer appendData:[SKProtobufEncoder encodeVarint:[packed length]]];
	[buffer appendData:packed];
	
	return [buffer autorelease];
}

@end
