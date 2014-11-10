//
//  EXChatWindowController.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKFriend.h"

@class SKSession, EXChatWindowController;

@protocol EXChatWindowControllerDelegate <NSObject>
- (void)shouldCloseController:(EXChatWindowController *)controller;
@end

@interface EXChatWindowController : NSWindowController <SKFriendChatDelegate, NSWindowDelegate>
{
	SKFriend *_remoteFriend;
	
	id <EXChatWindowControllerDelegate> _delegate;
}
@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSTextField *messageField;

@property (assign) id <EXChatWindowControllerDelegate> delegate;
@property (readonly) SKFriend *remoteFriend;

- (id)initWithFriend:(SKFriend *)remoteFriend;

- (IBAction)send:(id)sender;

@end
