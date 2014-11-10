//
//  BFWindow.m
//  BlackFire
//
//  Created by Antwan van Houdt on 12/27/11.
//  Copyright (c) 2011 Exurion. All rights reserved.
//

#import "BFWindow.h"

@implementation BFWindow

- (void)sendEvent:(NSEvent *)theEvent
{
	NSResponder *first = [self firstResponder];
	if( ! [first isKindOfClass:[NSTextView class]] )
	{
		// lookup the text field
		NSArray *subviews = [[self contentView] subviews];
		for(NSView *subview in subviews)
		{
			if( [subview isKindOfClass:[NSTextView class]] )
			{
				[self makeFirstResponder:subview];
			}
		}
	}
	[super sendEvent:theEvent];
}

@end
