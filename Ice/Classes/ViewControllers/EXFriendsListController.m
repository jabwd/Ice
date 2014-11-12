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
#import "SKSteamID.h"
#import "EXChatWindowController.h"

@implementation EXFriendsListController

- (id)initWithSession:(SKSession *)session
{
	if( (self = [super initWithNibName:@"EXFriendsListController" bundle:[NSBundle mainBundle]]) )
	{
		_session				= [session retain];
		_chatWindowControllers	= [[NSMutableArray alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadData)
													 name:SKFriendsListChangedNotificationName
												   object:_session];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(openChat:)
													 name:SKFriendNeedsChatWindowNotificationName
												   object:nil];
	}
	return self;
}

- (void)dealloc
{
	[_session release];
	_session = nil;
	[_chatWindowControllers release];
	_chatWindowControllers = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[_outlineView setTarget:self];
	[_outlineView setDoubleAction:@selector(doubleAction:)];
}

- (void)reloadData
{
	[_outlineView reloadData];
}

- (void)openChat:(NSNotification *)notification
{
	SKFriend *remoteFriend = (SKFriend *)notification.object;
	if( [remoteFriend isKindOfClass:[SKFriend class]] )
	{
		[self openChatForFriend:remoteFriend];
	}
	else
	{
		DLog(@"[Error] got a chat request from non SKFriend object");
	}
}

- (void)openChatForFriend:(SKFriend *)friend
{
	for(EXChatWindowController *existingController in _chatWindowControllers)
	{
		if( existingController.remoteFriend.steamID.rawSteamID == friend.steamID.rawSteamID )
		{
			[existingController.window makeKeyAndOrderFront:nil];
			return;
		}
	}
	
	EXChatWindowController *controller = [[EXChatWindowController alloc] initWithFriend:friend];
	controller.delegate = self;
	[_chatWindowControllers addObject:controller];
	[controller release];
}

- (void)shouldCloseController:(EXChatWindowController *)controller
{
	controller.delegate = nil;
	[_chatWindowControllers removeObject:controller];
}

- (IBAction)doubleAction:(id)sender
{
	NSInteger selectedRow = [_outlineView selectedRow];
	if( selectedRow > -1 )
	{
		SKFriend *item = [_outlineView itemAtRow:selectedRow];
		if( [item isKindOfClass:[SKFriend class]] )
		{
			[self openChatForFriend:item];
		}
	}
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
		return [_session.onlineFriends count];
	}
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if( item == nil )
	{
		return _session.onlineFriends[index];
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
	[view.imageView setImage:[NSImage imageNamed:@"avatar-default"]];
	[view.displayNameField setStringValue:[remoteFriend displayNameString]];
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
