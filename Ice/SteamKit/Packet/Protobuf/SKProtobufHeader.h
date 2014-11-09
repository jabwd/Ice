//
//  SKProtobufHeader.h
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKPacket;

@interface SKProtobufHeader : NSObject
{
	UInt64 _steamID; // Fixed64, 1
	UInt32 _sessionID; // UInt32, 2
	
	UInt64 _sourceID; // Fixed64, 10
	UInt64 _targetID; // FIxed64, 11
}

@property (assign) UInt64 steamID;
@property (assign) UInt32 sessionID;
@property (assign) UInt64 sourceID;
@property (assign) UInt64 targetID;

- (id)initWithPacket:(SKPacket *)packet;

@end
