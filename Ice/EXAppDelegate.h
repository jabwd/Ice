//
//  EXAppDelegate.h
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKSession.h"

@interface EXAppDelegate : NSObject <NSApplicationDelegate, SKSessionDelegate>
{
	SKSession *_session;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *packetDataField;

- (IBAction)scanPacketData:(id)sender;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;

@end
