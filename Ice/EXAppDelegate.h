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

@class EXSteamDeveloperWindow, EXFriendsListController, EXImageView;

@interface EXAppDelegate : NSObject <NSApplicationDelegate,
									SKSessionDelegate,
									EXSteamGuardWindowControllerDelegate,
									NSToolbarDelegate>
{
	SKSession *_session;
	NSString *_authcode;
	
	EXSteamDeveloperWindow	*_developerWindowController;
	EXFriendsListController *_friendsListController;
	
	NSToolbarItem *_toolbarItem;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *connectingView;
@property (assign) IBOutlet NSView *loginView;
@property (assign) IBOutlet NSView *toolbarView;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *passwordField;

@property (assign) IBOutlet NSPopUpButton *statusPopup;
@property (assign) IBOutlet EXImageView *avatarImageView;
@property (assign) IBOutlet NSImageView *statusImageView;
@property (assign) IBOutlet NSPopUpButton *namePopup;

@property (assign) IBOutlet NSProgressIndicator *loginIndicator;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)openDeveloperWindow:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (IBAction)selectStatus:(id)sender;

@end
