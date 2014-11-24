//
//  EXPreferencesWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXPreferencesWindowController.h"
#import "BFNotificationCenter.h"
#import "BFSoundSet.h"
#import "SKSentryFile.h"

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
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			NSString *soundsetsPath = [[SKSentryFile appSupportDirectory] stringByAppendingPathComponent:@"Soundsets"];
			_soundsets = [[NSMutableArray alloc] init];
			
			// find all the soundsets in the soundsets folder
			NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:soundsetsPath error:nil];
			if( [contents count] > 0 )
			{
				for(NSString *soundset in contents)
				{
					// Ignore this file
					if( [soundset isEqualToString:@".DS_Store"] )
					{
						continue;
					}
					
					// BFSoundSet will make sure that it is an *actual* soundset
					// Therefore checking more in terms of file name etc. isn't necessary here
					NSString *finalPath = [[NSString alloc] initWithFormat:@"%@/%@",soundsetsPath,soundset];
					BFSoundSet *set = [[BFSoundSet alloc] initWithContentsOfFile:finalPath];
					if( [set.name length] > 0 )
					{
						[_soundsets addObject:set];
					}
					[set release];
					[finalPath release];
				}
			}
			
			// now update the menu.
			dispatch_async(dispatch_get_main_queue(), ^{
				NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
				NSInteger i, cnt = [_soundsets count];
				NSString *currentPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"soundSetPath"];
				NSMenuItem *current = nil;
				current = [[NSMenuItem alloc] initWithTitle:@"Default soundpack" action:@selector(selectSoundSet:) keyEquivalent:@""];
				[current setTarget:self];
				[current setTag:-1];
				[menu addItem:current];
				[current release];
				for(i=0;i<cnt;i++)
				{
					BFSoundSet *set = _soundsets[i];
					NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:set.name action:@selector(selectSoundSet:) keyEquivalent:@""];
					[item setTarget:self];
					[item setTag:i];
					[menu addItem:item];
					if( [set.path isEqualToString:currentPath] )
						current = [item retain];
					
					[item release];
				}
				[_soundsetDropDown setMenu:menu];
				
				if( current )
					[_soundsetDropDown selectItem:current];
				[current release];
				[menu release];
				
				if( [_soundsets count] > 0 )
					[_soundsetDropDown setEnabled:YES];
				else
					[_soundsetDropDown setEnabled:NO];
			});
		});
	}
	return self;
}

- (void)dealloc
{
	[_soundsets release];
	_soundsets = nil;
	[super dealloc];
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

- (IBAction)selectSoundSet:(id)sender
{
	NSMenuItem *item = (NSMenuItem *)sender;
	if( [item isKindOfClass:[NSMenuItem class]] )
	{
		NSInteger index = [item tag];
		if( index >= 0 && index < [_soundsets count] )
		{
			BFSoundSet *soundSet = _soundsets[index];
			if( soundSet )
			{
				[[BFNotificationCenter defaultNotificationCenter] setSoundSet:soundSet];
				[[NSUserDefaults standardUserDefaults] setObject:soundSet.path forKey:@"soundSetPath"];
				[[BFNotificationCenter defaultNotificationCenter] playDemoSound];
			}
		}
		else if( index == -1 )
		{
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"soundSetPath"];
		}
	}
	else {
		NSLog(@"*** Unknown object %@ called selectSoundset",sender);
	}
}

- (IBAction)playTestSound:(id)sender
{
	[[BFNotificationCenter defaultNotificationCenter] updateSoundVolume];
	[[BFNotificationCenter defaultNotificationCenter] playConnectedSound];
}

@end
