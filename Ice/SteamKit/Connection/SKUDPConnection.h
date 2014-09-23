//
//  SKUDPConnection.h
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKConnection.h"
#import "GCDAsyncUdpSocket.h"

@interface SKUDPConnection : SKConnection <GCDAsyncUdpSocketDelegate>
{
	GCDAsyncUdpSocket *_UDPSocket;
	
	NSString	*_host;
	UInt16		_port;
	UInt32		_destination;	// something we receive from the steam server
								// during the login sequence
	UInt32		_sequence;		// Internal send sequence
	UInt32		_recvSeq;		// Internal received sequence
}

@property (readonly) NSString *host;
@property (readonly) UInt16 port;
@property (readonly) UInt32 destination;

/**
 * Returns a known server list
 * IP addresses, no hostnames ( have none at this time )
 *
 * @return NSArray servers ( NSString )
 */
+ (NSArray *)knownServerList;

/**
 * 'Connects' to a specific server address
 * The normal init method will just pick an address
 * from the known server list
 *
 * @return SKUDPConnection
 */
- (id)initWithServerAddress:(NSString *)server;

@end
