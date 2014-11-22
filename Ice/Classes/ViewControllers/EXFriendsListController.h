//
//  EXFriendsListController.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXChatWindowController.h"

@class SKSession, EXFriendsListRowView;

extern NSString *EXOnlineFriendsGroupName;
extern NSString *EXOfflineFriendsGroupName;
extern NSString *EXPendingFriendsGroupName;

@interface EXFriendsListController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate, EXChatWindowControllerDelegate>
{
	SKSession *_session;
	
	NSMutableArray *_chatWindowControllers;
	
	NSString *_onlineFriends;
	NSString *_offlineFriends;
	
	BOOL _notifications;
}
@property (assign) IBOutlet NSOutlineView *outlineView;

- (id)initWithSession:(SKSession *)session;
- (void)setSession:(SKSession *)session;

- (IBAction)doubleAction:(id)sender;

@end
