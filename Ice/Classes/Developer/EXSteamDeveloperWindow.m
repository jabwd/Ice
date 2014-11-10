//
//  EXSteamDeveloperWindow.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXSteamDeveloperWindow.h"
#import "SKProtobufScanner.h"
#import "NSData_SteamKitAdditions.h"
#import "SKAESEncryption.h"
#import "SKSession.h"

@interface EXSteamDeveloperWindow ()

@end

@implementation EXSteamDeveloperWindow

- (id)initWithSession:(SKSession *)session
{
	if( (self = [super initWithWindowNibName:@"EXSteamDeveloperWindow" owner:self]) )
	{
		_sessionKey = [session.sessionKey retain];
	}
	return self;
}

- (void)dealloc
{
	[_sessionKey release];
	_sessionKey = nil;
	[super dealloc];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	if( _sessionKey )
	{
		[_sessionKeyField setStringValue:[[_sessionKey description] substringWithRange:NSMakeRange(1, 32)]];
	}
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

@end
