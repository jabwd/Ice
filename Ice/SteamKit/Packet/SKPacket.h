//
//  SKPacket.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt16, SKPacketType)
{
	SKPacketTypeUnknown						= -1,
	SKPacketTypeConnectBegin				= 1,
	SKPacketTypeConnectChallenge			= 2,
	
	SKPacketTypeEncryptionRequest			= 100,
	SKPacketTypeEncryptionAccepted			= 101,
	
	SKPacketTypeConnectChallengeResponse	= 1027, // 0x0403
	SKPacketTypeClientDestination			= 1028, // 0x0404
	SKPacketTypeClient28ByteStream			= 1030, // 0x0406
	SKPacketTypeEncryptionResponse			= 1030, // 0x0406
	SKPacketTypeCorruptedPacketSent			= 1031, // 0x0407 // This is what I think it means, don't actually know.
};

extern NSInteger const SKPacketMinimumDataLength;
extern NSInteger const SKPacketTCPMagicHeader;
extern NSInteger const SKPacketUDPMagicHeader;

extern UInt32 const		SKLocalIPObfuscationMask;
extern UInt32 const		SKProtocolVersion;
extern UInt32 const		SKProtocolVersionMajorMask;
extern UInt32 const		SKProtocolVersionMinorMask;



@interface SKPacket : NSObject
{
	NSData *_data;
	
	UInt16			_len;						// Length of the packtes data ( minus the header )
	SKPacketType	_type;						// Some type
	UInt32			_destination;				// Some internal IDing system
	UInt32			_source;					// obv.
	UInt32			_sequenceNumber;			// Seq number of this packet
	UInt32			_lastReceivedSeqNumber;		// Last seq # received from the server
	UInt32			_splitCount;				// Number of packets the massage is split in
	UInt32			_firstSeqNumber;			// Sequence number of the first packet in the series
	UInt32			_dataLength;				// Of the total message, so spans over more packets
												// If split count > 1
	BOOL _isTCP;
}

@property (atomic, retain) NSData *data;

@property (assign) SKPacketType type;
@property (assign) UInt32 destination;
@property (assign) UInt32 source;
@property (assign) UInt32 sequenceNumber;
@property (assign) UInt32 lastReceivedSeqNumber;
@property (assign) UInt32 splitCount;
@property (assign) UInt32 firstSeqNumber;
@property (assign) UInt32 dataLength;
@property (assign) BOOL isTCP;

+ (SKPacket *)packetByDecodingTCPBuffer:(NSData *)buffer sessionKey:(NSData *)sessionKey error:(NSError **)error;
+ (SKPacket *)packetByDecodingUDPBuffer:(NSData *)buffer error:(NSError **)error;

- (id)initWithDataString:(NSString *)dataString;

- (NSData *)generate;
- (NSData *)iv;

//----------------------------------------------------------------------------------------------+
// Packet templates

+ (SKPacket *)connectPacket;
+ (SKPacket *)connectChallengePacket:(NSData *)payload;
+ (SKPacket *)encryptionResponsePacket:(NSData *)sessionKey tcp:(BOOL)isTCP;
+ (SKPacket *)logOnPacket:(NSString *)username password:(NSString *)password
				 language:(NSString *)language;

@end
