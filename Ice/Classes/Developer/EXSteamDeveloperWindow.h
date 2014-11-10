//
//  EXSteamDeveloperWindow.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SKSession;

@interface EXSteamDeveloperWindow : NSWindowController
{
	NSData *_sessionKey;
}

@property (assign) IBOutlet NSTextField *packetDataField;
@property (assign) IBOutlet NSTextField *sessionKeyField;
@property (assign) IBOutlet NSTextField *dataField;

- (id)initWithSession:(SKSession *)session;

- (IBAction)scanPacketData:(id)sender;
- (IBAction)decryptData:(id)sender;
- (IBAction)encryptData:(id)sender;

@end
