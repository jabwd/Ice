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

- (void)addHeaderValue:(SKProtobufValue *)value forType:(WireType)type fieldNumber:(UInt32)fieldNumber;
- (void)addValue:(SKProtobufValue *)value forType:(WireType)type fieldNumber:(UInt32)fieldNumber;

- (NSData *)generate;

@end
