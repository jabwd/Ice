//
//  EXAppDelegate.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXAppDelegate.h"
#import "SKSession.h"
#import "SKSentryFile.h"
#import "EXSteamDeveloperWindow.h"
#import "EXFriendsListController.h"
#import "BFNotificationCenter.h"
#import "EXImageView.h"

#import "EXPreferencesWindowController.h"

@implementation EXAppDelegate

+ (void)initialize
{
	NSNumber *n_YES	= [[NSNumber alloc] initWithBool:YES];
	//NSNumber *n_NO	= [[NSNumber alloc] initWithBool:NO];
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
						  @100.0f,BFSoundVolumeDefaultsKey,
						  n_YES, @"onlineFriendSound",
						  n_YES, @"offlineFriendSound",
						  n_YES, @"messageReceiveSound",
						  n_YES, @"messageSendSound",
						  n_YES, @"connectSound",
						  n_YES, @"rememberUsername",
						  n_YES, @"rememberPassword",
						  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
	[dict release];
	[n_YES release];
}

- (void)dealloc
{
	[_session disconnect];
	[_session release];
	_session = nil;
	[_authcode release];
	_authcode = nil;
	[_developerWindowController release];
	_developerWindowController = nil;
	[_friendsListController release];
	_friendsListController = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self switchMainView:_loginView];
	
	NSString *defaultUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultUsername"];
	if( defaultUsername && [[NSUserDefaults standardUserDefaults] boolForKey:@"rememberUsername"] )
	{
		[_usernameField setStringValue:defaultUsername];
		[self.window makeFirstResponder:_passwordField];
	}
	else
	{
		[self.window makeFirstResponder:_usernameField];
	}
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(notificationReceived:)
	 name:SKLoginFailedSteamGuardNotificationName object:nil];
	
	
	NSToolbar*toolbar = [[NSToolbar alloc] initWithIdentifier:@"friendsListToolbar"];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration: YES];
	[toolbar setSizeMode:               NSToolbarSizeModeSmall];
	[toolbar setDisplayMode:            NSToolbarDisplayModeIconOnly];
	
	_toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"status"];
	[_toolbarItem setView:_toolbarView];
	[_toolbarItem setMinSize:NSMakeSize(168.0, NSHeight([_toolbarView frame]))];
	[_toolbarItem setMaxSize:NSMakeSize(1920.0, NSHeight([_toolbarView frame]))];
	
	[toolbar      setDelegate:self];
	[_window	setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	return _toolbarItem;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)aToolbar
{
	return @[@"status"];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)aToolbar
{
	return @[@"status"];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	return YES;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	// Makes the chat with the most missed messages the front
	// In many cases this is the most important chat
	// TODO: Use timestamps?
	/*if( [_chatControllers count] > 0 )
	{
		BFChat *targetChat = nil;
		NSUInteger top = 0;
		for(BFChat *chat in _chatControllers)
		{
			// if the new chat has more missed messages than the other one
			// make it the new main priority
			if( chat.missedMessages > 0 && chat.missedMessages > top )
			{
				top = chat.missedMessages;
				targetChat = chat;
			}
		}
		
		// finally make our target chat front
		if( targetChat ) {
			[targetChat.windowController selectChat:targetChat];
			[targetChat.windowController.window makeKeyAndOrderFront:self];
			return NO;
		}
	}*/
	
	// default behavior
	if( ![_window isVisible] )
	{
		[_window makeKeyAndOrderFront:self];
	}
	return NO;
}

- (void)notificationReceived:(NSNotification *)notification
{
	if( [notification.name isEqualToString:SKLoginFailedSteamGuardNotificationName] )
	{
		NSString *email = [notification userInfo][@"email"];
		EXSteamGuardWindowController *controller = [[EXSteamGuardWindowController alloc] initWithEmailName:email];
		controller.delegate = self;
		[controller.window makeKeyAndOrderFront:self];
	}
}

- (void)steamGuardEndedWithCode:(NSString *)code controller:(EXSteamGuardWindowController *)controller
{
	controller.delegate = nil;
	[controller.window close];
	[controller release];
	[_authcode release];
	_authcode = [code retain];
	[self connect:nil];
}

- (IBAction)connect:(id)sender
{
	if( _session )
	{
		DLog(@"Already connected!");
		return;
	}
	_session = [[SKSession alloc] init];
	_session.delegate = self;
	[_session connect];
}

- (IBAction)disconnect:(id)sender
{
	[_session disconnect];
}

- (IBAction)showPreferences:(id)sender
{
	[[EXPreferencesWindowController sharedController] show];
}

- (IBAction)openDeveloperWindow:(id)sender
{
	if( _developerWindowController )
	{
		[_developerWindowController.window makeKeyAndOrderFront:self];
	}
	else
	{
		_developerWindowController = [[EXSteamDeveloperWindow alloc] initWithSession:_session];
		[self openDeveloperWindow:nil];
	}
}

- (void)switchMainView:(NSView *)view
{
	NSView *contentView = self.window.contentView;
	NSArray *subviews = [contentView subviews];
	[subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	
	[view setFrameSize:contentView.frame.size];
	[contentView addSubview:view];
	NSRect frame = [view frame];
	frame.origin.y++;
	[view setFrame:frame];
}

#pragma mark - SKSession delegate

- (void)session:(SKSession *)session didDisconnectWithReason:(SKResultCode)reason
{
	DLog(@"Disconnected with reason: %u", reason);
}

- (void)sessionChangedStatus:(SKSession *)session
{
	switch((SKSessionStatus)session.status)
	{
		case SKSessionStatusOffline:
		{
			[_friendsListController release];
			_friendsListController = nil;
			_session.delegate = nil;
			[_session release];
			_session = nil;
			[_authcode release];
			_authcode = nil;
			
			[_namePopup setEnabled:NO];
			[[_namePopup itemAtIndex:0] setTitle:@""];
			[_statusPopup setEnabled:NO];
			[_avatarImageView setAvatarImage:nil];
			[[_statusPopup itemAtIndex:0] setTitle:@"Offline"];
			[_statusImageView setImage:[NSImage imageNamed:@"NSStatusNone"]];
			
			[self switchMainView:_loginView];
		}
			break;
			
		case SKSessionStatusConnecting:
		{
			[self switchMainView:_connectingView];
			[_loginIndicator setIndeterminate:YES];
			[_loginIndicator setUsesThreadedAnimation:YES];
			[_loginIndicator startAnimation:nil];
		}
			break;
			
		case SKSessionStatusConnected:
		{
			[[NSUserDefaults standardUserDefaults] setObject:[_usernameField stringValue] forKey:@"defaultUsername"];
			if( !_friendsListController )
			{
				_friendsListController = [[EXFriendsListController alloc] initWithSession:_session];
			}
			[self switchMainView:_friendsListController.view];
			
			[_namePopup setEnabled:YES];
			[[_namePopup itemAtIndex:0] setTitle:[_session.currentUser displayNameString]];
			[_statusPopup setEnabled:YES];
			[_avatarImageView setAvatarImage:[_session.currentUser avatarImage]];
			[[_statusPopup itemAtIndex:0] setTitle:@"Available"];
			[_statusImageView setImage:[NSImage imageNamed:@"NSStatusAvailable"]];
			
			[[BFNotificationCenter defaultNotificationCenter] playConnectedSound];
		}
			break;
			
		default:
			break;
	}
}

- (IBAction)selectStatus:(id)sender
{
	SKPersonaState state = (SKPersonaState)[sender tag];
	if( state == SKPersonaStateOffline )
	{
		//[self disconnect:nil];
		//return;
	}
	[_session setUserStatus:state];
	NSString *statusString = nil;
	NSImage *image = [NSImage imageNamed:@"NSStatusAvailable"];
	switch(state)
	{
		case SKPersonaStateOffline:
			statusString = @"Offline";
			image = [NSImage imageNamed:@"NSStatusNone"];
			break;
		case SKPersonaStateAway:
			statusString = @"Away";
			image = [NSImage imageNamed:@"NSStatusUnavailable"];
			break;
		case SKPersonaStateBusy:
			statusString = @"Busy";
			image = [NSImage imageNamed:@"NSStatusPartiallyAvailable"];
			break;
		case SKPersonaStateLookingToPlay:
			statusString = @"Looking to Play";
			break;
		case SKPersonaStateLookingToTrade:
			statusString = @"Looking to Trade";
			break;
		case SKPersonaStateMax:
			statusString = @"Error :D";
			break;
		case SKPersonaStateOnline:
			statusString = @"Available";
			break;
		case SKPersonaStateSnooze:
			statusString = @"Sleeping";
			image = [NSImage imageNamed:@"NSStatusNone"];
			break;
	}
	[_statusImageView setImage:image];
	[[_statusPopup itemAtIndex:0] setTitle:statusString];
}

- (void)updateSentryFile:(NSString *)fileName data:(NSData *)data
{
	SKSentryFile *file = [[SKSentryFile alloc] initWithSession:_session];
	[file createWithData:data fileName:fileName];
	[file release];
}

- (NSString *)username
{
	return [_usernameField stringValue];
}

- (NSString *)password
{
	return [_passwordField stringValue];
}

- (NSString *)steamGuard
{
	return _authcode;
}

@end
