//
//  EXSteamGuardWindowController.h
//  Ice
//
//  Created by Antwan van Houdt on 28/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EXSteamGuardWindowController;

@protocol EXSteamGuardWindowControllerDelegate <NSObject>
- (void)steamGuardEndedWithCode:(NSString *)code controller:(EXSteamGuardWindowController *)controller;
@end

@interface EXSteamGuardWindowController : NSWindowController <NSTextFieldDelegate>
{
	NSString *_email;
	id <EXSteamGuardWindowControllerDelegate> _delegate;
}

@property (assign) id delegate;

@property (assign) IBOutlet NSTextField *codeField;
@property (assign) IBOutlet NSTextField *label;

@property (assign) IBOutlet NSButton *okButton;
@property (assign) IBOutlet NSButton *cancelButton;

- (id)initWithEmailName:(NSString *)emailName;

- (IBAction)okAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
