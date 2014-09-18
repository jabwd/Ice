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
