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
	NSMutableDictionary	*_map;
}

- (id)initWithData:(NSData *)packetData;

#pragma mark - Accessing the data stream

+ (UInt32)readVarint:(NSData *)data;

/**
 * Loads the given Mapping file from the disk
 * by looking in the appBundle
 *
 * @param NSString mapName	the name of the file in Protobuf/(*).plist
 * 
 * @return void
 */
- (void)loadMap:(NSString *)mapName;

/**
 * This method can only be used if loadMap: was called earlier
 * otherwise there is no way to figure out what the string key
 * its field number is
 *
 * @param NSString key		the map's key
 *
 * @return id	the associated value
 */
- (id)valueForKey:(NSString *)key;

/**
 * Returns the value at the given field number
 *
 * @param NSUInteger fieldNumber	the field number
 *									that you want to scan
 *
 * @return id		the value in the format of a specified WireType
 */
- (id)valueForFieldNumber:(NSUInteger)fieldNumber;

/**
 * Used for determining what type a certain fieldNumber has
 *
 * @param NSUInteger	fieldNumber
 *
 * @return WireType		the protobuf WireType
 */
- (WireType)typeAtFieldNumber:(NSUInteger)fieldNumber;

@end
