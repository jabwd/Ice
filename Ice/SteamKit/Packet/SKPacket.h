//
//  SKPacket.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SteamConstants.h"

extern NSInteger const SKPacketMinimumDataLength;
extern NSInteger const SKPacketTCPMagicHeader;
extern NSInteger const SKPacketUDPMagicHeader;

extern UInt32 const		SKLocalIPObfuscationMask;
extern UInt32 const		SKProtocolVersion;
extern UInt32 const		SKProtocolVersionMajorMask;
extern UInt32 const		SKProtocolVersionMinorMask;

@class SKProtobufScanner;

@interface SKPacket : NSObject
{
	NSData				*_data;
	NSData				*_raw;
	SKProtobufScanner	*_protobufScanner;
	
	SKMsgType		_msgType;
}

@property (atomic, retain) NSData *data;
@property (readonly, getter = getRaw) NSData *raw;
@property (assign) SKMsgType msgType;

+ (SKPacket *)packetByDecodingTCPBuffer:(NSData *)buffer sessionKey:(NSData *)sessionKey error:(NSError **)error;
+ (SKPacket *)packetByDecodingUDPBuffer:(NSData *)buffer error:(NSError **)error;

- (NSData *)generate;

- (BOOL)isProtobufPacket;

- (id)valueForKey:(NSString *)key;
- (id)valueForFieldNumber:(NSUInteger)fieldNumber;

//----------------------------------------------------------------------------------------------+
// Packet templates

+ (SKPacket *)encryptionResponsePacket:(NSData *)sessionKey;
+ (SKPacket *)logOnPacket:(NSString *)username password:(NSString *)password
				 language:(NSString *)language;

@end
