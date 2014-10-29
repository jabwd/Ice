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
	SKSessionStatusConnecting		= 4,
	SKSessionStatusUnknown			= -1
};

extern NSString *SKSessionStatusChangedNotificationName;
extern NSString *SKLoginFailedSteamGuardNotificationName;

@class SKUDPConnection, SKTCPConnection, SKSession;

@protocol SKSessionDelegate <NSObject>
- (void)sessionChangedStatus:(SKSession *)session;
- (NSString *)username;
- (NSString *)password;
- (NSString *)steamGuard;

- (void)updateSentryFile:(NSString *)fileName data:(NSData *)data;
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

+ (id)sharedSession;

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

/**
 * Is called by the packetScanner when the Encryption challeng was accepted
 * and we should start the login sequence.
 *
 * @return void
 */
- (void)logIn;

- (void)updateSentryFile:(NSString *)fileName data:(NSData *)data;

- (NSString *)username;
- (NSString *)password;
- (NSString *)steamGuard;

@end
