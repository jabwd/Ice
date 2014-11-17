//
//  EXFriendsListRowView.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXFriendsListRowView.h"

@implementation EXFriendsListRowView

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
	
	[self.textField setFrame:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
}

@end
