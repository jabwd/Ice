//
//  EXOutlineView.m
//  Ice
//
//  Created by Antwan van Houdt on 17/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXOutlineView.h"

@implementation EXOutlineView

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	if( [[self itemAtRow:row] isKindOfClass:[NSString class]] )
	{
		return [super frameOfCellAtColumn:column row:row];
	}
	NSRect cellFrame		= [super frameOfCellAtColumn:column row:row];
	cellFrame.size.width	+= cellFrame.origin.x-14;
	cellFrame.origin.x		= 8;
	return cellFrame;
}

- (void)highlightSelectionInClipRect:(NSRect)rect
{
	[[NSColor blackColor] set];
	NSRectFill(rect);
}

@end
