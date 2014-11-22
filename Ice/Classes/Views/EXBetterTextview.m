//
//  EXBetterTextview.m
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXBetterTextview.h"
#import "EXChatWindowController.h"

@implementation EXBetterTextview

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	EXChatWindowController *controller = (EXChatWindowController *)self.delegate;
	[controller scrollToBottom];
}

@end
