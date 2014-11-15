//
//  EXMemoryManager.h
//  Ice
//
//  Created by Antwan van Houdt on 14/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EXMemoryManager : NSObject
{
	NSMutableDictionary *_list;
}
+ (instancetype)sharedManager;

- (void)add:(NSDictionary *)entry;

- (void)putout;
- (void)track;
- (void)untrack;

@end
