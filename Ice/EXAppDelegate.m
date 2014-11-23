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
	
	NSString *bla = [NSString stringWithContentsOfFile:@"/Users/jabwd/Desktop/Bla.plist" encoding:NSUTF8StringEncoding error:nil];
	NSLog(@"%@", bla);
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
			[[BFNotificationCenter defaultNotificationCenter] playConnectedSound];
		}
			break;
			
		default:
			break;
	}
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
