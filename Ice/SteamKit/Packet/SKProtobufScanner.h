//
//  SKProtobufScanner.h
//  Ice
//
//  Created by Antwan van Houdt on 23/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, WireType)
{
	WireTypeVarint		= 0,
	WireTypeFixed		= 1,
	WireTypePacked		= 2,
	WireTypeDeprecated1 = 3,
	WireTypeDeprecated2 = 4,
	WireTypeFloat		= 5
};

extern NSUInteger const ProtoMask; // AND for isProto, XOR for STRIP

@interface SKProtobufScanner : NSObject
{
	NSData				*_data;
	NSMutableArray		*_values;
	NSMutableDictionary	*_body;
	NSMutableDictionary *_header;
}

@property (retain) NSMutableDictionary *body;
@property (retain) NSMutableDictionary *header;

- (id)initWithData:(NSData *)packetData;

@end
