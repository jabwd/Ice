//
//  SKProtobufCompiler.m
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufCompiler.h"
#import "SKProtobufValue.h"
#import "SKProtobufKey.h"

@implementation SKProtobufCompiler

- (id)init
{
	if( (self = [super init]) )
	{
		_headerValues	= [[NSMutableDictionary alloc] init];
		_bodyValues		= [[NSMutableDictionary alloc] init];
		_headerData		= [[NSMutableData alloc] init];
		_data			= [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_headerValues release];
	_headerValues = nil;
	[_bodyValues release];
	_bodyValues = nil;
	[_data release];
	_data = nil;
	[_headerData release];
	_headerData = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (void)addHeaderValue:(SKProtobufValue *)value fieldNumber:(UInt32)fieldNumber
{
	SKProtobufKey *key = [[SKProtobufKey alloc] initWithType:value.type fieldNumber:fieldNumber];
	[_headerData appendData:[key encode]];
	[_headerData appendData:value.data];
	[key release];
}

- (void)addValue:(SKProtobufValue *)value fieldNumber:(UInt32)fieldNumber
{
	SKProtobufKey *key = [[SKProtobufKey alloc] initWithType:value.type fieldNumber:fieldNumber];
	[_data appendData:[key encode]];
	[_data appendData:value.data];
	[key release];
}

- (void)addHeaderValue:(SKProtobufValue *)value forType:(WireType)type fieldNumber:(UInt32)fieldNumber
{
	[self addHeaderValue:value fieldNumber:fieldNumber];
}

- (void)addValue:(SKProtobufValue *)value forType:(WireType)type fieldNumber:(UInt32)fieldNumber
{
	[self addValue:value fieldNumber:fieldNumber];
}

- (NSData *)generate
{
	UInt32 headerLength = (UInt32)[_headerData length];
	NSMutableData *final = [[NSMutableData alloc] init];
	[final appendBytes:&headerLength length:4];
	[final appendData:_headerData];
	[final appendData:_data];
	NSData *res = [NSData dataWithData:final];
	[final release];
	return res;
}

@end
