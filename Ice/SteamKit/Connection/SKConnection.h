//
//  SKConnection.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SKConnectionStatusOffline       = 0,
    SKConnectionStatusConnecting    = 1,
    SKConnectionStatusDisconnecting = 3,
    SKConnectionStatusOnline        = 2
} SKConnectionStatus;

@class SKPacket;
@class SKSession;
@class SKPacketScanner;

@interface SKConnection : NSObject
{
	SKSession		*_session;
	SKPacketScanner *_scanner;
    NSMutableData   *_buffer;
	NSString		*_host;
    
    unsigned long       _dataCount;
	SKConnectionStatus  _status;
	UInt32				_destination;
	UInt16				_port;
}

@property (readonly) SKConnectionStatus status;
@property (retain) NSMutableData *buffer;
@property (retain) SKSession *session;
@property (assign) UInt32 destination;
@property (retain) NSString *host;
@property (assign) UInt16 port;

+ (NSString *)connectionStatusToString:(SKConnectionStatus)status;

- (id)initWithAddress:(NSString *)address;

- (void)connect;
- (void)disconnect;

- (void)sendData:(NSData *)data;
- (void)sendPacket:(SKPacket *)packet;

- (void)removeBytesOfLength:(NSUInteger)length;

@end
