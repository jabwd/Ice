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

@implementation EXAppDelegate

- (void)dealloc
{
	[_session disconnect];
	[_session release];
	_session = nil;
	[_authcode release];
	_authcode = nil;
	[_developerWindowController release];
	_developerWindowController = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.window.titlebarAppearsTransparent=YES;
	
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
	[_session release];
	_session = nil;
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

#pragma mark - SKSession delegate

- (void)sessionChangedStatus:(SKSession *)session
{
	switch((SKSessionStatus)session.status)
	{
		case SKSessionStatusOffline:
		{
			_session.delegate = nil;
			[_session release];
			_session = nil;
		}
			break;
			
		case SKSessionStatusConnected:
		{
			[_session setUserStatus:SKPersonaStateOnline];
		}
			break;
			
		default:
			break;
	}
}

- (void)updateSentryFile:(NSString *)fileName data:(NSData *)data
{
	SKSentryFile *file = [[SKSentryFile alloc] init];
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
