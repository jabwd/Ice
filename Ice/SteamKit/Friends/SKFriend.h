//
//  SKFriend.h
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKSteamID;

@interface SKFriend : NSObject
{
	NSString *_displayName;
	NSString *_username;
	NSString *_password;
	NSString *_email;
	
	NSString *_countryCode;
	
	SKSteamID *steamID;
	
	UInt32 _lastLogon;
	UInt32 _lastLogoff;
	UInt32 _onlineInstances;
	UInt32 _currentInstance;
}

@property (retain) NSString *displayName;
@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *email;
@property (retain) NSString *countryCode;

@property (retain) SKSteamID *steamID;

@property (assign) UInt32 lastLogon;
@property (assign) UInt32 lastLogoff;
@property (assign) UInt32 onlineInstances;
@property (assign) UInt32 currentInstance;

- (NSString *)displayName;

@end
