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
	NSRect cellFrame		= [super frameOfCellAtColumn:column row:row];
	cellFrame.size.width	+= cellFrame.origin.x-8;
	cellFrame.origin.x		= 8;
	return cellFrame;
}

@end
