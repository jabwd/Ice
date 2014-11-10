//
//  EXChatWindowController.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SKFriend, SKSession;

@interface EXChatWindowController : NSWindowController
{
	SKFriend *_remoteFriend;
}

- (id)initWithFriend:(SKFriend *)remoteFriend;

- (IBAction)send:(id)sender;

@end
