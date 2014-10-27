//
//  SKProtobufKey.h
//  Ice
//
//  Created by Antwan van Houdt on 24/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufScanner.h"

@interface SKProtobufKey : NSObject
{
	UInt32		_fieldNumber;
	WireType	_type;
}

@property (assign) UInt32 fieldNumber;
@property (assign) WireType type;

- (id)initWithVarint:(UInt32)varint;
- (id)initWithType:(WireType)wireType fieldNumber:(UInt32)number;

- (NSData *)encode;
- (NSString *)valueKey;

@end
