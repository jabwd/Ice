//
//  SKPacketScanner.h
//  Ice
//
//  Created by Antwan van Houdt on 14/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKConnection, SKSession;

@interface SKPacketScanner : NSObject
{
	SKConnection	*_connection;
	SKSession		*_session;
}

/**
 * Creates a new SKPacketScanner with the given connection as its
 * connection host which is used to get data from for scanning.
 * The connection is responsible for calling checkForPacket
 * to notify the scanner there is new data available
 *
 * @param SKConnection the host connection
 *
 * @return SKPacketScanner
 */
- (id)initWithConnection:(SKConnection *)connection;

#pragma mark - Scanning packets

/**
 * Checks the current buffer of the host connection to see
 * if there is a valid SKPacket available for scanning and handling
 *
 * @return void
 */
- (void)checkForPacket:(NSData *)buffer;

@end
