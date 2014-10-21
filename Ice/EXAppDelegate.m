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
#import "NSData_XfireAdditions.h"
#import "SKAESEncryption.h"
#import "SKSentryFile.h"

@implementation EXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.window.titlebarAppearsTransparent=YES;
	/*
	 cf5ba375723a8fac4ad0a267009159f92d106e84e1c5efc2e93413f2ac42f3af
	 91ef00e2a8a4cd95172844dae9b0ea46af60904b5f885e466cd6114989773822d6bc6b812906cbfd2ede52d667caf9c2510b5082f3aba152f976baffa8f7a052e3b44ff42f09fcfc490aab82128a5a8af70bcc668cd45849b476dc25eee06b75
	 
	 f8 33 32 03 c4 62 c9 6d d1 d6 46 fe 58 b0 d7 f7 ad f7 a5 8b 74 90 7c 64 b0 52 55 f3 b3 8a db bc 01 08 ab 80 04 10 8e e4 97 d0 07 28 eb 0d 32 07 65 6e 67 6c 69 73 68 38 b5 fe ff ff 0f 92 03 08 6e 75 6d 62 65 72 35 5f 9a 03 09 78 74 39 41 42 53 35 76 64 90 05 09
	 
	 8a150080 09000000 09000000 00010010 0108ab80 04108ee4 97d00728 eb0d3207 656e676c 69736838 b5feffff 0f920308 6e756d62 6572355f 9a030978 74394142 53357664 900509
	 */
	/*NSLog(@"%@", [[NSData dataFromByteString:@"010000800000000012b98080800035000000ef0200800e00000009ae63320a0100100110c9aace03083f4209676d61696c2e636f6d503fa101ae63320a01001001c00100c80100"] enhancedDescription]);
	
	NSLog(@"%@", [[NSData dataFromByteString:@"01000080 00000000 12b88080 80003400 0000ef02 00800d00 000009ae 63320a01 00100110 edcf2e08 3f420967 6d61696c 2e636f6d 503fa101 ae63320a 01001001 c00100c8 0100"] enhancedDescription]);
	
	[self connect:nil];*/
}

- (IBAction)scanPacketData:(id)sender
{
	NSBeep();
	DLog(@"");
}

- (IBAction)decryptData:(id)sender
{
	NSData *data		= [NSData dataFromByteString:[_sessionKeyField stringValue]];
	NSData *packetData	= [NSData dataFromByteString:[_dataField stringValue]];
	
	NSData *decrypted = [SKAESEncryption decryptPacketData:packetData key:data];
	NSLog(@"Decrypted: %@", [decrypted enhancedDescription]);
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
	DLog(@"Session changed: %u", session.status);
}

- (NSString *)username
{
	return [_usernameField stringValue];
}

- (NSString *)password
{
	return [_passwordField stringValue];
}

@end
