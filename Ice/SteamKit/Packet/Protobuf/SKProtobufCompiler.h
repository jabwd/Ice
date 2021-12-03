//
//  SKProtobufCompiler.h
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufConstants.h"

@class SKProtobufKey;
@class SKProtobufValue;

@interface SKProtobufCompiler : NSObject
{
	NSMutableDictionary *_headerValues;
	NSMutableDictionary *_bodyValues;
	NSMutableData		*_data;
	NSMutableData		*_headerData;
}

- (void)addString:(NSString *)string field:(UInt32)fieldNumber;
- (void)addFixed32:(UInt32)value field:(UInt32)fieldNumber;
- (void)addFixed64:(UInt64)value field:(UInt32)fieldNumber;
- (void)addVarint:(UInt64)varint field:(UInt32)fieldNumber;

- (void)addData:(NSData *)data forType:(WireType)type fieldNumber:(UInt32)fieldNumber;


- (void)addHeaderValue:(SKProtobufValue *)value forType:(WireType)type fieldNumber:(UInt32)fieldNumber;
- (void)addValue:(SKProtobufValue *)value forType:(WireType)type fieldNumber:(UInt32)fieldNumber;

- (void)addHeaderValue:(SKProtobufValue *)value fieldNumber:(UInt32)fieldNumber;
- (void)addValue:(SKProtobufValue *)value fieldNumber:(UInt32)fieldNumber;

- (NSData *)generate;

@end
