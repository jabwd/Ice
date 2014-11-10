//
//  EXChatWindowController.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKFriend.h"

@class SKSession;

@interface EXChatWindowController : NSWindowController <SKFriendChatDelegate>
{
	SKFriend *_remoteFriend;
}
@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSTextField *messageField;

- (id)initWithFriend:(SKFriend *)remoteFriend;

- (IBAction)send:(id)sender;

@end
