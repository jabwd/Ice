//
//  SKFriend.h
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKFriend : NSObject
{
	NSString *_displayName;
	NSString *_username;
	NSString *_password;
	NSString *_email;
	
	NSString *_countryCode;
}

@property (retain) NSString *displayName;
@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *email;
@property (retain) NSString *countryCode;

@end
