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
#import "SFTabStripView.h"

@class SKSession, EXChatWindowController;

@protocol EXChatWindowControllerDelegate <NSObject>
- (void)shouldCloseController:(EXChatWindowController *)controller;
- (SKFriend *)newRemoteFriendForID:(SteamID *)steamID;
@end

typedef NS_ENUM(UInt32, EXChatMessageType)
{
	EXChatMessageTypeSelf			= 0,
	EXChatMessageTypeFriend			= 1,
	EXChatMessageTypeNotification	= 2,
};

@interface EXChatWindowController : NSWindowController <SKFriendChatDelegate, NSWindowDelegate, BFChatMessageViewDelegate>
{
	SKFriend *_remoteFriend;
	
	id <EXChatWindowControllerDelegate> _delegate;
	
	UInt64 _previousStamp;
	UInt32 _missedMessagesCount;
}
@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet XNResizingMessageView *messageView;
@property (assign) IBOutlet NSImageView *isTypingView;
@property (assign) IBOutlet SFTabStripView *stripView;

@property (assign) id <EXChatWindowControllerDelegate> delegate;
@property (readonly) SKFriend *remoteFriend;

- (id)initWithFriend:(SKFriend *)remoteFriend;

- (void)goOffline;
- (void)scrollToBottom;

@end
