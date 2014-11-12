//
//  SKProtobufScanner.h
//  Ice
//
//  Created by Antwan van Houdt on 23/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKProtobufConstants.h"


extern NSUInteger const ProtoMask; // AND for isProto, XOR for STRIP

@interface SKProtobufScanner : NSObject
{
	NSData				*_data;
	NSMutableDictionary	*_body;
	NSMutableDictionary *_header;
}

@property (retain) NSMutableDictionary *body;
@property (retain) NSMutableDictionary *header;

- (id)initWithData:(NSData *)packetData;

- (void)scanBody:(NSMutableData *)body;

/**
 * Scans a repeated field into an NSArray ( if applicable )
 *
 * @return NSArray repeated entries ( if available )
 */
- (NSArray *)scanRepeated:(NSData *)repeated;
@end
