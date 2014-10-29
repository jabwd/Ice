//
//  EXAppDelegate.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXAppDelegate.h"
#import "SKPacket.h"
#import "SKSession.h"
#import "NSData_SteamKitAdditions.h"
#import "SKAESEncryption.h"
#import "SKSentryFile.h"
#import "SKProtobufScanner.h"
#import "SKProtobufValue.h"
#import "SKProtobufCompiler.h"
#import "SKProtobufConstants.h"
#import "SKProtobufKey.h"

@implementation EXAppDelegate

- (void)dealloc
{
	[_session disconnect];
	[_session release];
	_session = nil;
	[_authcode release];
	_authcode = nil;
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

- (IBAction)scanPacketData:(id)sender
{
	SKProtobufScanner *scanner = [[SKProtobufScanner alloc] initWithData:[NSData dataFromByteString:[_packetDataField stringValue]]];
	NSLog(@"%@ %@", scanner.header, scanner.body);
	[scanner release];
}

- (IBAction)decryptData:(id)sender
{
	NSData *data		= [NSData dataFromByteString:[_sessionKeyField stringValue]];
	NSData *packetData	= [NSData dataFromByteString:[_dataField stringValue]];
	
	NSData *decrypted = [SKAESEncryption decryptPacketData:packetData key:data];
	NSLog(@"Decrypted: %@", decrypted);
}

- (IBAction)encryptData:(id)sender
{
	NSData *data			= [NSData dataFromByteString:[_sessionKeyField stringValue]];
	NSData *dataToEncrypt	= [NSData dataFromByteString:[_dataField stringValue]];
	
	NSData *encrypted = [SKAESEncryption encryptPacketData:dataToEncrypt key:data];
	NSLog(@"Encrypted: %@", encrypted);
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
	
	[_sessionKeyField setStringValue:[[_session.sessionKey description] substringWithRange:NSMakeRange(1, 32)]];
}

- (IBAction)disconnect:(id)sender
{
	[_session disconnect];
	[_session release];
	_session = nil;
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
			
		default:
			break;
	}
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
