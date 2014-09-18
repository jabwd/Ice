//
//  SKPacket.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	SKPacketIDUnknown = -1
} SKPacketID;

@interface SKPacket : NSObject
{
	NSData *_data;
	
	UInt16 _len;					// Length of the packtes data ( minus the header )
	UInt16 _type;					// Some type
	UInt32 _destination;			//
	UInt32 _source;					//
	UInt32 _sequenceNumber;			// Seq number of this packet
	UInt32 _lastReceivedSeqNumber;	// Last seq # received from the server
	UInt32 _splitCount;				// Number of packets the massage is split in
	UInt32 _firstSeqNumber;			// Sequence number of the first packet in the series
	UInt32 _dataLength;				// Of the total message, so spans over more packets
									// If split count > 1
	
	BOOL _newPacket;				// Determines whether this is one we should scan or generate
}

@property (atomic, retain) NSData *data;

@property (assign) UInt16 type;
@property (assign) UInt32 destination;
@property (assign) UInt32 source;
@property (assign) UInt32 sequenceNumber;
@property (assign) UInt32 lastReceivedSeqNumber;
@property (assign) UInt32 splitCount;
@property (assign) UInt32 firstSeqNumber;
@property (assign) UInt32 dataLength;

- (id)initWithDataString:(NSString *)dataString;
- (id)initWithData:(NSData *)data;

- (BOOL)isValid;
- (NSData *)generate;

//----------------------------------------------------------------------------------------------+
// Packet templates
+ (SKPacket *)connectPacket;

@end
