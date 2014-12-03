//
//  EXStringPromptController.m
//  Ice
//
//  Created by Antwan van Houdt on 03/12/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXStringPromptController.h"

@interface EXStringPromptController ()

@end

@implementation EXStringPromptController

- (id)initWithNibName:(NSString *)name completionHandler:(void (^)(void))completionHandler
{
	if( (self = [super initWithWindowNibName:name owner:self]) )
	{
		
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
