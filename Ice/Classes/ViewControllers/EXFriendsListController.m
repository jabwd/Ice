//
//  EXFriendsListController.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXFriendsListController.h"

@implementation EXFriendsListController

- (id)initWithSession:(SKSession *)session
{
	if( (self = [super initWithNibName:@"EXFriendsListController" bundle:[NSBundle mainBundle]]) )
	{
		_session = [session retain];
	}
	return self;
}

- (void)dealloc
{
	[_session release];
	_session = nil;
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
