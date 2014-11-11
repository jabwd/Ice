//
//  SKFriend.h
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SteamConstants.h"

@class SKSteamID, SKSession;

@protocol SKFriendChatDelegate <NSObject>
- (void)friendDidReceiveMessage:(NSString *)message
						   date:(NSDate *)date
						   type:(SKChatEntryType)entryType;
@end

@interface SKFriend : NSObject
{
	NSString *_displayName;
	NSString *_username;
	NSString *_password;
	NSString *_email;
	NSString *_gameName;
	
	NSString *_countryCode;
	
	SKSteamID *_steamID;
	SKSession *_session;
	
	NSData *_avatarHash;
	
	NSMutableArray *_storedMessages;
	
	id _delegate;
	
	SKPersonaState _status;
	UInt32 _lastLogon;
	UInt32 _lastLogoff;
	UInt32 _onlineInstances;
	UInt32 _currentInstance;
	UInt32 _appID;
}

@property (retain) NSString *displayName;
@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *email;
@property (retain) NSString *countryCode;
@property (retain) NSString *gameName;
@property (retain) NSData *avatarHash;

@property (retain) SKSteamID *steamID;
@property (retain) SKSession *session;
@property (assign) id <SKFriendChatDelegate> delegate;

@property (assign) SKPersonaState status;
@property (assign) UInt32 lastLogon;
@property (assign) UInt32 lastLogoff;
@property (assign) UInt32 onlineInstances;
@property (assign) UInt32 currentInstance;
@property (assign) UInt32 appID;

/**
 * Creates an SKFriend object with the given protobuf
 * body. This method should be updated when the protobuf
 * fieldNumbers change
 *
 * @param NSDictionary body			| the body of the packet
 *
 * @return SKFriend	remoteFriend	| a new instance of SKFriend
 */
- (id)initWithBody:(NSDictionary *)body;

/**
 * Updates the current SKFriend object with the given
 * protobuf body and sends out notifications
 * according to the changes
 *
 * @param NSDictionary body		| the body with the changes
 *
 * @return void
 */
- (void)updateWithBody:(NSDictionary *)body;

/**
 * Specific accessor for the displayName
 * to allow the GUI to more easily always display
 * a name even if we don't have a nickname set
 *
 * @return NSString	displayName	or steamID string rep
 */
- (NSString *)displayName;

/**
 * Handles the given incoming msg protobuf body
 * and passes down its contents to the chat delegate
 *
 * @param NSDictionary	body	| the protobuf body
 *
 * @return void
 */
- (void)receivedChatMessageWithBody:(NSDictionary *)body;

/**
 * Generates a sendMessage packet and sends it over the current
 * session's connection
 *
 * @param NSString	message				| optional
 * @param SKChatEntryType	entryType	| determines what kind of message
 *										| is to be sent, like an isTyping note
 *
 * @return void
 */
- (void)sendMessage:(NSString *)message ofType:(SKChatEntryType)entryType;


- (NSComparisonResult)displayNameSort:(SKFriend *)other;

@end
