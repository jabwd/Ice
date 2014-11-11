//
//  EXAppDelegate.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKSession.h"
#import "EXSteamGuardWindowController.h"

@class EXSteamDeveloperWindow, EXFriendsListController;

@interface EXAppDelegate : NSObject <NSApplicationDelegate,
									SKSessionDelegate,
									EXSteamGuardWindowControllerDelegate>
{
	SKSession *_session;
	NSString *_authcode;
	
	EXSteamDeveloperWindow	*_developerWindowController;
	EXFriendsListController *_friendsListController;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView	*contentView;
@property (assign) IBOutlet NSTableView *modeView;
@property (assign) IBOutlet NSView *connectingView;
@property (assign) IBOutlet NSView *loginView;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *passwordField;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)openDeveloperWindow:(id)sender;

@end
