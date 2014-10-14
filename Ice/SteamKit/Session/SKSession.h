//
//  SKSession.h
//  Ice
//
//  Created by Antwan van Houdt on 22/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt32, SKSessionStatus)
{
	SKSessionStatusOffline			= 0,
	SKSessionStatusLoggingIn		= 1,
	SKSessionStatusConnected		= 2,
	SKSessionStatusDisconnecting	= 3,
	SKSessionStatusUnknown			= -1
};

extern NSString *SKSessionStatusChangedNotificationName;

@class SKUDPConnection, SKTCPConnection, SKSession;

@protocol SKSessionDelegate <NSObject>
- (void)sessionChangedStatus:(SKSession *)session;
@end

@interface SKSession : NSObject
{
	NSData *_sessionKey;
	
	SKUDPConnection *_UDPConnection;
	SKTCPConnection *_TCPConnection;
	
	id <SKSessionDelegate>	_delegate;
	SKSessionStatus			_status;
}

@property (nonatomic, assign) id <SKSessionDelegate> delegate;
@property (readonly) NSData *sessionKey;
@property (readonly) SKSessionStatus status;

/** 
 * Generates a sessionKey for use in the steam server communication
 *
 * @return NSData	containing a 32 byte randomly generated
 *					data stream
 */
+ (NSData *)generateSessionKey;

#pragma mark - Connection handling

/**
 * Creates a new TCP socket and attempts ot log in to the steam network
 *
 * @return void
 */
- (void)connect;

/**
 * Destroys the current TCP Socket and stops communication
 * with the steam network
 *
 * @return void
 */
- (void)disconnect;

@end
