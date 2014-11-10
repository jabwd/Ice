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
	
	id _delegate;
	
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

@property (assign) UInt32 lastLogon;
@property (assign) UInt32 lastLogoff;
@property (assign) UInt32 onlineInstances;
@property (assign) UInt32 currentInstance;
@property (assign) UInt32 appID;

- (id)initWithBody:(NSDictionary *)body;

- (NSString *)displayName;

- (void)receivedChatMessageWithBody:(NSDictionary *)body;

@end
