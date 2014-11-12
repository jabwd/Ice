//
//  SKSteamID.h
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKSteamID : NSObject
{
	UInt64 _rawSteamID;
}

@property (readonly) UInt64 rawSteamID;

- (id)initWithRawSteamID:(UInt64)rawID;

- (UInt32)accountID;

- (UInt32)accountInstance;

- (UInt32)accountType;

- (UInt32)accountUniverse;

@end
