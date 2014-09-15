//
//  SKPacket.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKPacket : NSObject
{
	NSData *_data;
}

@property (readonly) NSData *data;

- (void)generate;

@end
