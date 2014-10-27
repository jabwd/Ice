//
//  SKProtobufValue.h
//  Ice
//
//  Created by Antwan van Houdt on 27/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufConstants.h"

@interface SKProtobufValue : NSObject

- (id)initWithData:(NSData *)data type:(WireType)type;
- (id)initWithVarint:(UInt64)varint;
- (id)initWithFixed:(UInt64)fixed64;
- (id)initWithString:(NSString *)string;

@end
