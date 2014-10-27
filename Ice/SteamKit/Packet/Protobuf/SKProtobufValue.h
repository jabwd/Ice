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
	id			_value;
	
	WireType	_type;
}
@property (retain) NSData *data;
@property (assign) WireType type;
@property (retain) id value;

- (id)initWithData:(NSData *)data type:(WireType)type;

- (id)initWithVarint:(UInt64)varint;
- (id)initWithFixed64:(UInt64)fixed64;
- (id)initWithFixed32:(UInt32)fixed32;
- (id)initWithString:(NSString *)string;

#pragma mark - Methods

/**
 * Returns the length of the data of the value
 * so it is easier to remove bytes or increase the position
 * for in a scanner of data
 *
 * @return NSUInteger		_data's length
 */
- (NSUInteger)length;

@end
