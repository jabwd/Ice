//
//  SKProtobufEncoder.m
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufEncoder.h"

@implementation SKProtobufEncoder

+ (SKProtobufEncoder *)sharedEncoder
{
	static SKProtobufEncoder *_sharedEncoder = nil;
	if( !_sharedEncoder )
	{
		_sharedEncoder = [[[self class] alloc] init];
	}
	return _sharedEncoder;
}

- (id)init
{
	if( (self = [super init]) )
	{
		
	}
	return self;
}

- (NSData *)encodeVarint:(UInt64)value
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

@end
