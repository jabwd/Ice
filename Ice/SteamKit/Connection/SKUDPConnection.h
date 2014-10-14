//
//  SKUDPConnection.h
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKConnection.h"
#import "GCDAsyncUdpSocket.h"

@class SKSession;

@interface SKUDPConnection : SKConnection <GCDAsyncUdpSocketDelegate>
{
	GCDAsyncUdpSocket	*_UDPSocket;
	
	UInt32		_sequence;		// Internal send sequence
	UInt32		_recvSeq;		// Internal received sequence
}

/**
 * Returns a known server list
 * IP addresses, no hostnames ( have none at this time )
 *
 * @return NSArray servers ( NSString )
 */
+ (NSArray *)knownServerList;

@end
