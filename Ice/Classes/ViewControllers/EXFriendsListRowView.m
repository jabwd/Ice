//
//  EXFriendsListRowView.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXFriendsListRowView.h"

@implementation EXFriendsListRowView

- (void)dealloc
{
	[_avatarImage release];
	_avatarImage = nil;
	[super dealloc];
}

- (void)setShowsStatusField:(BOOL)showsStatus
{
	NSRect rect = self.textField.frame;
	
	if( showsStatus )
	{
		rect.origin.y = 16;
		[_statusField setHidden:NO];
	}
	else
	{
		rect.origin.y = 10;
		[_statusField setHidden:YES];
	}
	
	NSTextField *textField = self.textField;
	//DLog(@"Visible: %lf %lf", [self visibleRect].size.width, [self visibleRect].size.height);
	if( [self visibleRect].size.width != 162.0f )
	{
		//textField = [textField animator];
	}
	[textField setFrame:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
}

- (void)_setShowsStatusField:(BOOL)showsStatus
{
	NSRect rect = self.textField.frame;
	
	if( showsStatus )
	{
		rect.origin.y = 16;
		[_statusField setHidden:NO];
	}
	else
	{
		rect.origin.y = 10;
		[_statusField setHidden:YES];
	}
	
	NSTextField *textField = self.textField;
	[[textField animator] setFrame:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if( self.backgroundStyle == NSBackgroundStyleDark )
	{
		[self.statusField setTextColor:[NSColor whiteColor]];
	}
	else
	{
		[self.statusField setTextColor:[NSColor colorWithCalibratedWhite:0.4f alpha:1.0f]];
	}
	
	if( _avatarImage )
	{
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSBezierPath *curvePath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(2, 2, 32, 32) xRadius:16 yRadius:16];
		[curvePath setClip];
		[_avatarImage drawInRect:NSMakeRect(2, 2, 32, 32)
						fromRect:NSZeroRect
					   operation:NSCompositeSourceOver
						fraction:1.0f];
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
}

@end
