//
//  EXPreferencesWindowController.h
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(UInt32, EXPrefTabTag)
{
	EXPrefTabGeneral		= 0,
	EXPrefTabSound			= 1,
	EXPrefTabAdvanced		= 2,
};

@interface EXPreferencesWindowController : NSWindowController

@property (assign) IBOutlet NSToolbar *toolbar;
@property (assign) IBOutlet NSView *generalView;
@property (assign) IBOutlet NSView *soundView;
@property (assign) IBOutlet NSView *advancedView;

+ (instancetype)sharedController;

- (IBAction)selectPane:(id)sender;
- (void)show;



//- Sound view -//
- (IBAction)playTestSound:(id)sender;

@end
