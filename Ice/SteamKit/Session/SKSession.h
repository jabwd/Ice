//
//  SKSession.h
//  Ice
//
//  Created by Antwan van Houdt on 22/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SteamConstants.h"

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
extern NSString *SKFriendsListChangedNotificationName;
extern NSString *SKFriendNeedsChatWindowNotificationName;

@class SKUDPConnection, SKTCPConnection, SKSession;
@class SKFriend, SKSteamID;

@protocol SKSessionDelegate <NSObject>
- (void)sessionChangedStatus:(SKSession *)session;
- (void)session:(SKSession *)session didDisconnectWithReason:(SKResultCode)reason;

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
	
	SKFriend		*_currentUser;
	NSString		*_loginKey;
	NSTimer			*_keepAliveTimer;
	
	NSMutableArray *_onlineFriends;
	NSMutableArray *_offlineFriends;
	NSMutableArray *_pendingFriends;
	
	id <SKSessionDelegate>	_delegate;
	SKSessionStatus			_status;
	SKPersonaState			_userStatus;
	
	UInt32 _uniqueID;
	UInt32 _sessionID;
	UInt32 _keepAliveTimerSeconds;
	UInt64 _targetID;
	UInt64 _rawSteamID;
}

@property (nonatomic, assign) id <SKSessionDelegate> delegate;
@property (readonly) NSData *sessionKey;
@property (assign) SKSessionStatus status;
@property (readonly) SKFriend *currentUser;
@property (readonly) NSMutableArray *onlineFriends;
@property (readonly) NSMutableArray *offlineFriends;
@property (readonly) SKTCPConnection *TCPConnection;

@property (retain) NSString *loginKey;
@property (assign) UInt32 uniqueID;
@property (assign) UInt32 sessionID;
@property (assign) UInt32 keepAliveTimerSeconds;
@property (assign) UInt64 targetID;
@property (assign) UInt64 rawSteamID;

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
- (void)disconnectWithReason:(SKResultCode)reason;

/**
 * Is called by the packetScanner when the Encryption challeng was accepted
 * and we should start the login sequence.
 *
 * @return void
 */
- (void)logIn;

#pragma mark - Setting up basic information

/**
 * Adds a reference SKFriend to the friends list to be 
 * populated with information later on
 * Don't confuse this method with adding / sending
 * a friend request, thats not what it does.
 *
 * @param SKFriend remoteFriend | the friend to add to the list
 *
 * @return void
 */
- (void)updateFriend:(NSDictionary *)packetData;
- (void)connectionAddFriend:(SKFriend *)remoteFriend moreComing:(BOOL)moreComing;
- (void)addPendingFriend:(SKFriend *)pendingFriend;
- (void)sortFriendsList;
- (SKFriend *)friendForSteamID:(SKSteamID *)steamID;
- (SKFriend *)friendForRawSteamID:(UInt64)rawSteamID;

- (void)requestAppInfo:(UInt32)appID;

- (void)setUserStatus:(SKPersonaState)status;
- (SKPersonaState)userStatus;

/**
 * Updates the current SKSentryFile with the new fileName and data
 * Updates the userDefaults and marks the new fileName as the current
 * sentryFile for the next connect
 *
 * @param NSString fileName | the file name requested by steam
 * @param NSData	data	| the data of the file ( 2048 bytes usually )
 *
 * @return void
 */
- (void)updateSentryFile:(NSString *)fileName data:(NSData *)data;

- (NSString *)username;
- (NSString *)password;
- (NSString *)steamGuard;

@end
