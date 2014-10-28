//
//  EXSteamGuardWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 28/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXSteamGuardWindowController.h"

@interface EXSteamGuardWindowController ()

@end

@implementation EXSteamGuardWindowController

- (id)initWithEmailName:(NSString *)emailName
{
	if( (self = [super initWithWindowNibName:@"EXSteamGuardWindowController" owner:self]) )
	{
		_email = [emailName retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_email release];
	_email = nil;
	_delegate = nil;
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	[_label setStringValue:[NSString stringWithFormat:[_label stringValue], _email]];
}

- (void)textDidChange:(NSNotification *)notification
{
	[_codeField setStringValue:[[_codeField stringValue] uppercaseString]];
	if( [[_codeField stringValue] length] == 5 )
	{
		[_okButton setEnabled:YES];
	}
	else if( [[_codeField stringValue] length] > 5 )
	{
		[_codeField setStringValue:[[_codeField stringValue] substringWithRange:NSMakeRange(0, 5)]];
	}
	else
	{
		[_okButton setEnabled:NO];
	}
}

- (IBAction)okAction:(id)sender
{
	[_delegate steamGuardEndedWithCode:[_codeField stringValue] controller:self];
}

- (IBAction)cancelAction:(id)sender
{
	[_delegate steamGuardEndedWithCode:nil controller:self];
}

@end
