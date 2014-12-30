//
//  EXImageView.m
//  Ice
//
//  Created by Antwan van Houdt on 21/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXImageView.h"

@implementation EXImageView

- (void)dealloc
{
	[_avatarImage release];
	_avatarImage = nil;
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect drawRect = [self bounds];
	if( _avatarImage )
	{
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSBezierPath *curvePath = [NSBezierPath bezierPathWithRoundedRect:drawRect xRadius:4 yRadius:4];
		[curvePath setLineWidth:1.0f];
		[curvePath setClip];
		[_avatarImage drawInRect:drawRect];
		
		[[NSColor colorWithCalibratedWhite:0.2f alpha:1.0f] set];
		[curvePath stroke];
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
}

@end
