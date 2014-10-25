//
//  SKProtobufKey.m
//  Ice
//
//  Created by Antwan van Houdt on 24/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufKey.h"

@implementation SKProtobufKey

- (id)initWithByte:(const char *)byte
{
	if( (self = [super init]) )
	{
		_type			= (*byte & 0x07);
		_fieldNumber	= ((*byte & 0xF8) >> 3);
	}
	return self;
}

- (id)initWithType:(WireType)wireType fieldNumber:(UInt8)number
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
	UInt8 byte = _type;
	byte |= (_fieldNumber << 3);
	return [NSData dataWithBytes:&byte length:1];
}

- (NSString *)valueKey
{
	return [NSString stringWithFormat:@"Proto.%u", _fieldNumber];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[SKProtobufKey Field=%u WireType=%u]", _fieldNumber, _type];
}

@end
