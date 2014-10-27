//
//  SKProtobufKey.m
//  Ice
//
//  Created by Antwan van Houdt on 24/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufKey.h"

@implementation SKProtobufKey

- (id)initWithVarint:(UInt32)varint
{
	if( (self = [super init]) )
	{
		_type			= (varint & 0x00000007);
		_fieldNumber	= ((varint ^ 0x00000007) >> 3);
	}
	return self;
}

- (id)initWithType:(WireType)wireType fieldNumber:(UInt32)number
{
	if( (self = [super init]) )
	{
		_type			= wireType;
		_fieldNumber	= number;
	}
	return self;
}

- (NSData *)encode
{
	UInt32 byte = _type;
	byte |= (_fieldNumber << 3);
	return [NSData dataWithBytes:&byte length:1];
}

- (NSString *)valueKey
{
	return [NSString stringWithFormat:@"%u", _fieldNumber];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKProtobufKey Field=%u WireType=%u]", _fieldNumber, _type];
}

@end
