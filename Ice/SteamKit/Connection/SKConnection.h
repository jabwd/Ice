//
//  SKConnection.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

typedef enum {
    SKConnectionStatusOffline       = 0,
    SKConnectionStatusConnecting    = 1,
    SKConnectionStatusDisconnecting = 3,
    SKConnectionStatusOnline        = 2
} SKConnectionStatus;

@interface SKConnection : NSObject <GCDAsyncSocketDelegate>
{
    GCDAsyncSocket  *_socket;
    NSMutableData   *_buffer;
    
    SKConnectionStatus  _status;
    unsigned long       _dataCount;
}

@property (readonly) SKConnectionStatus status;

+ (NSString *)connectionStatusToString:(SKConnectionStatus)status;

- (void)connect;
- (void)disconnect;

- (void)sendData:(NSData *)data;

@end
