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

- (id)initWithDestination:(UInt32)destination;

@end
