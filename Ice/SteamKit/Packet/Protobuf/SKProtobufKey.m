//
//  SKProtobufKey.m
//  Ice
//
//  Created by Antwan van Houdt on 24/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufKey.h"
#import "SKProtobufValue.h"

@implementation SKProtobufKey

- (id)initWithVarint:(UInt64)varint
{
	if( (self = [super init]) )
	{
		UInt32 fNumber	= (UInt32)varint;
		_type			= (varint & 0x00000007);
		_fieldNumber	= ((fNumber ^ 0x00000007) >> 3);
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
	SKProtobufValue *value = [[SKProtobufValue alloc] initWithVarint:byte];
	return value.data;
}

- (NSString *)valueKey
{
	return [NSString stringWithFormat:@"%u.%u", _fieldNumber, _type];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKProtobufKey Field=%u WireType=%u]", _fieldNumber, _type];
}

@end
