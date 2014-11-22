//
//  EXPreferencesWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXPreferencesWindowController.h"
#import "BFNotificationCenter.h"

@interface EXPreferencesWindowController ()

@end

@implementation EXPreferencesWindowController

+ (instancetype)sharedController
{
	static EXPreferencesWindowController *controller = nil;
	if( !controller )
	{
		controller = [[EXPreferencesWindowController alloc] init];
	}
	return controller;
}

- (id)init
{
	if( (self = [super initWithWindowNibName:@"EXPreferencesWindowController" owner:self]) )
	{
		
	}
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self selectPane:EXPrefTabGeneral];
	[_toolbar setSelectedItemIdentifier:@"General"];
}

- (void)show
{
	[self.window makeKeyAndOrderFront:self];
}

- (IBAction)selectPane:(id)sender
{
	switch((EXPrefTabTag)[sender tag])
	{
		case EXPrefTabGeneral:
			[self switchView:_generalView];
			break;
			
		case EXPrefTabSound:
			[self switchView:_soundView];
			break;
			
		case EXPrefTabAdvanced:
			[self switchView:_advancedView];
			break;
			
		default:
			DLog(@"Unhandled preferences tag");
			break;
	}
}

- (void)switchView:(NSView *)aView
{
	NSWindow *window = [self window];
	NSView *mainView = [window contentView];
	
	// first get rid of all th e subviews
	// Since 10.6 there is an API for that, but lets not get dependent just yet:
	NSArray *subViews = [mainView subviews];
	[subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	// get sizes for the animating resize
	NSRect frame      = window.frame;
	NSRect frameMain  = mainView.frame;
	NSRect frameView  = aView.frame;
	
	float add_height = frameView.size.height - frameMain.size.height;
	frame.size.height += add_height;
	frame.origin.y    -= add_height;
	
	// perform the animation
	[window setFrame:frame display:YES animate:YES];
	
	// finalize
	[mainView addSubview:aView];
	aView.frame = mainView.bounds;
}

#pragma mark - Sound view

- (IBAction)playTestSound:(id)sender
{
	[[BFNotificationCenter defaultNotificationCenter] updateSoundVolume];
	[[BFNotificationCenter defaultNotificationCenter] playConnectedSound];
}

@end
