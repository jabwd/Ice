//
//  SKPacket.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SteamConstants.h"

extern NSInteger const SKPacketTCPMagicHeader;
extern NSInteger const SKPacketUDPMagicHeader;

extern UInt32 const		SKLocalIPObfuscationMask;
extern UInt32 const		SKProtocolVersion;
extern UInt32 const		SKProtocolVersionMajorMask;
extern UInt32 const		SKProtocolVersionMinorMask;
extern UInt32 const		SKProtocolProtobufMask;

@class SKProtobufScanner, SKSession, SKFriend;

@interface SKPacket : NSObject
{
	NSData				*_data;
	NSData				*_raw;
	SKProtobufScanner	*_protobufScanner;
	
	SKMsgType		_msgType;
}

@property (retain) NSData *data;
@property (readonly, getter = getRaw) NSData *raw;
@property (assign) SKMsgType msgType;
@property (retain) SKProtobufScanner *scanner;

+ (SKPacket *)packetByDecodingTCPBuffer:(NSData *)buffer sessionKey:(NSData *)sessionKey error:(NSError **)error;
+ (SKPacket *)packetByDecodingUDPBuffer:(NSData *)buffer error:(NSError **)error;

- (NSData *)generate;

- (BOOL)isProtobufPacket;

- (id)valueForKey:(NSString *)key;
- (id)valueForFieldNumber:(NSUInteger)fieldNumber;

/**
 * Encrypts the packet with the given session's sessionKey
 * Using AES256 encryption
 *
 * @param SKSession session
 *
 * @return void
 */
- (void)encryptWithSession:(SKSession *)session;

//----------------------------------------------------------------------------------------------+
// Packet templates

+ (SKPacket *)encryptionResponsePacket:(NSData *)sessionKey;
+ (SKPacket *)logOnPacket:(SKSession *)session
				 language:(NSString *)language;

+ (SKPacket *)machineAuthResponsePacket:(UInt32)length
								session:(SKSession *)session;

+ (SKPacket *)loginKeyAccepted:(SKSession *)session;
+ (SKPacket *)heartBeatPacket:(SKSession *)session;
+ (SKPacket *)changeUserStatusPacket:(SKSession *)session;

+ (SKPacket *)sendMessagePacket:(NSString *)message
						 friend:(SKFriend *)remoteFriend
						session:(SKSession *)session
						   type:(SKChatEntryType)entryType;

@end
