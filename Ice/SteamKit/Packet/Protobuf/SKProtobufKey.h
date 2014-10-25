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
	UInt8		_fieldNumber;
	WireType	_type;
}

@property (assign) UInt8 fieldNumber;
@property (assign) WireType type;

- (id)initWithByte:(const char *)byte;
- (id)initWithType:(WireType)wireType fieldNumber:(UInt8)number;

- (NSData *)encode;

@end
