//
//  SKServerListManager.h
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKServerListManager : NSObject
{
	NSMutableArray *_list;
}

/**
 * Is used when the instance is not going to be used
 * to create a new cache file ( usually after connecting this is done )
 *
 * @return SKServerListManager manager | a manager with a server list
 *									   | if one was previously obtained
 */
- (id)initWithCache;

- (void)addServer:(UInt32)IP port:(UInt16)port;
- (void)save;

- (NSString *)getRandomAddress;

@end
