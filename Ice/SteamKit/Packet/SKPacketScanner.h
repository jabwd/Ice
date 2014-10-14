//
//  SKPacketScanner.h
//  Ice
//
//  Created by Antwan van Houdt on 14/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKConnection;

@interface SKPacketScanner : NSObject
{
	SKConnection *_connection;
}

- (id)initWithConnection:(SKConnection *)connection;

- (void)checkForPacket;

@end
