//
//  SKProtobufEncoder.h
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKProtobufEncoder : NSObject
+ (NSData *)encodeVarint:(UInt64)value;
+ (NSData *)encodeFixed64:(UInt64)fixedValue;
+ (NSData *)encodeFixed32:(UInt32)fixedValue;
+ (NSData *)encodeString:(NSString *)stringValue;
+ (NSData *)encodeData:(NSData *)packed;
@end
