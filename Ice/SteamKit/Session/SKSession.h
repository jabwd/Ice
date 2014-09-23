//
//  SKSession.h
//  Ice
//
//  Created by Antwan van Houdt on 22/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKSession : NSObject
{
	UInt32 _destination;
}

@property (readonly) UInt32 destination;

/** 
 * Generates a sessionKey for use in the steam server communication
 *
 * @return NSData	containing a 32 byte randomly generated
 *					data stream
 */
+ (NSData *)generateSessionKey;

- (id)initWithDestination:(UInt32)destination;

@end
