//
//  EXFriendsListController.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXFriendsListController.h"
#import "SKSession.h"
#import "EXFriendsListRowView.h"
#import "SKFriend.h"

@implementation EXFriendsListController

- (id)initWithSession:(SKSession *)session
{
	if( (self = [super initWithNibName:@"EXFriendsListController" bundle:[NSBundle mainBundle]]) )
	{
		_session = [session retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadData)
													 name:SKFriendsListChangedNotificationName
												   object:_session];
	}
	return self;
}

- (void)dealloc
{
	[_session release];
	_session = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)reloadData
{
	DLog(@"=> Updating friends list");
	[_outlineView reloadData];
}

#pragma mark - Outlineview datasource

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( item == nil )
	{
		return [_session.friendsList count];
	}
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if( item == nil )
	{
		return _session.friendsList[index];
	}
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	SKFriend *remoteFriend = (SKFriend *)item;
	if( item == nil )
	{
		return nil;
	}
	EXFriendsListRowView *view = [outlineView makeViewWithIdentifier:@"FriendCell" owner:self];
	if( !view )
	{
		DLog(@"[Error] cannot make friends cell view");
	}
	[view.displayNameField setStringValue:[remoteFriend displayName]];
	return view;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	NSUInteger row = [outlineView rowForItem:item];
	NSTableRowView *rowView = [outlineView rowViewAtRow:row makeIfNecessary:YES];
	if( rowView )
	{
		return rowView;
	}
	return nil;
}

@end
