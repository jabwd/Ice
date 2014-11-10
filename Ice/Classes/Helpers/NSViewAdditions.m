//
//  NSViewAdditions.m
//  BlackFire
//
//  Created by Antwan van Houdt on 11/7/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#import "NSViewAdditions.h"

@implementation NSView (Additions)

- (void)orderOnTop
{
	[self orderOnTopOfView:nil];
}

- (void)orderOnTopOfView:(NSView *)otherView
{
	NSView *superview = [self superview];
	[self removeFromSuperview];
	[superview addSubview:self positioned:NSWindowAbove relativeTo:otherView];
}

@end
