//
//  EXChatWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXChatWindowController.h"

@interface EXChatWindowController ()

@end

@implementation EXChatWindowController

- (id)initWithFriend:(SKFriend *)remoteFriend
{
	if( (self = [super init]) )
	{
		_remoteFriend = [remoteFriend retain];
	}
	return self;
}

- (void)dealloc
{
	[_remoteFriend release];
	_remoteFriend = nil;
	[super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)send:(id)sender
{
	
}

@end
