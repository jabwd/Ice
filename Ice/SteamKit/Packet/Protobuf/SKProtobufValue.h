//
//  SKProtobufValue.h
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufConstants.h"

@interface SKProtobufValue : NSObject
{
	NSData		*_data;
	
	WireType	_type;
}
@property (retain) NSData *data;
@property (assign) WireType type;

- (id)initWithData:(NSData *)data type:(WireType)type;

- (id)initWithVarint:(UInt64)varint;
- (id)initWithFixed64:(UInt64)fixed64;
- (id)initWithFixed32:(UInt32)fixed32;
- (id)initWithString:(NSString *)string;

@end
