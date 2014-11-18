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

#import "EXMemoryManager.h"

@implementation EXAppDelegate

+ (void)initialize
{
	//NSNumber *n_YES	= [[NSNumber alloc] initWithBool:YES];
	//NSNumber *n_NO	= [[NSNumber alloc] initWithBool:NO];
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
						  @100.0f,BFSoundVolumeDefaultsKey,
						  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
	[dict release];
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
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(notificationReceived:)
	 name:SKLoginFailedSteamGuardNotificationName object:nil];
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

- (IBAction)outputMemoryList:(id)sender
{
	[[EXMemoryManager sharedManager] putout];
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
}

#pragma mark - SKSession delegate

- (void)session:(SKSession *)session didDisconnectWithReason:(SKResultCode)reason
{
	
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
			[_loginIndicator setIndeterminate:YES];
			[_loginIndicator setUsesThreadedAnimation:YES];
			[_loginIndicator startAnimation:nil];
		}
			break;
			
		case SKSessionStatusConnecting:
		{
			[self switchMainView:_connectingView];
		}
			break;
			
		case SKSessionStatusConnected:
		{
			if( !_friendsListController )
			{
				_friendsListController = [[EXFriendsListController alloc] initWithSession:_session];
			}
			[self switchMainView:_friendsListController.view];
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
