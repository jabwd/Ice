//
//  EXChatWindowController.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKFriend.h"
#import "XNResizingMessageView.h"

@class SKSession, EXChatWindowController, SFTabStripView;

@protocol EXChatWindowControllerDelegate <NSObject>
- (void)shouldCloseController:(EXChatWindowController *)controller;
@end

@interface EXChatWindowController : NSWindowController <SKFriendChatDelegate, NSWindowDelegate, BFChatMessageViewDelegate>
{
	SKFriend *_remoteFriend;
	
	id <EXChatWindowControllerDelegate> _delegate;
	
	UInt32 _missedMessagesCount;
}
@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSTextField *messageField;
@property (assign) IBOutlet NSVisualEffectView *effectView;
@property (assign) IBOutlet NSImageView *isTypingView;
@property (assign) IBOutlet SFTabStripView *stripView;

@property (assign) id <EXChatWindowControllerDelegate> delegate;
@property (readonly) SKFriend *remoteFriend;

- (id)initWithFriend:(SKFriend *)remoteFriend;

- (IBAction)send:(id)sender;

@end
