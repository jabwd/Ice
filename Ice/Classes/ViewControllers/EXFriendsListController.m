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

NSString *EXOnlineFriendsGroupName = @"Online Friends";
NSString *EXOfflineFriendsGroupName = @"Offline Friends";
NSString *EXPendingFriendsGroupName = @"Pending Friends";

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
		if( [item isKindOfClass:[SKFriend class]] && item.status != SKPersonaStateOffline )
		{
			[self openChatForFriend:item];
		}
	}
}

#pragma mark - Outlineview datasource

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if( [item isKindOfClass:[SKFriend class]] )
	{
		return 36.0f;
	}
	return 24.0f;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	if( [item isKindOfClass:[NSString class]] )
	{
		return YES;
	}
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if( [item isKindOfClass:[SKFriend class]] )
	{
		return YES;
	}
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	if( [item isKindOfClass:[NSString class]] )
	{
		return YES;
	}
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if( [item isKindOfClass:[NSString class]] )
	{
		return YES;
	}
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( item == nil )
	{
		return 2;
	}
	else if( [item isEqualToString:EXOnlineFriendsGroupName] )
	{
		return [_session.onlineFriends count];
	}
	else if( [item isEqualToString:EXOfflineFriendsGroupName] )
	{
		return [_session.offlineFriends count];
	}
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if( item == nil )
	{
		if( index == 0 )
		{
			return EXOnlineFriendsGroupName;
		}
		else
		{
			return EXOfflineFriendsGroupName;
		}
	}
	else if( [item isEqualToString:EXOnlineFriendsGroupName] )
	{
		return _session.onlineFriends[index];
	}
	else if( [item isEqualToString:EXOfflineFriendsGroupName] )
	{
		return _session.offlineFriends[index];
	}
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [item isKindOfClass:[SKFriend class]] )
	{
		SKFriend *remoteFriend = (SKFriend *)item;
		
		EXFriendsListRowView *view = [outlineView makeViewWithIdentifier:@"FriendCell" owner:self];
		[view.imageView setImage:[NSImage imageNamed:@"avatar-default"]];
		[view.textField setStringValue:[remoteFriend displayNameString]];
		
		if( remoteFriend.status != SKPersonaStateOnline )
		{
			[view setShowsStatusField:YES];
			[view.statusField setStringValue:[remoteFriend statusDisplayString]];
		}
		else
		{
			[view setShowsStatusField:NO];
			[view.statusField setStringValue:@"Online"];
		}
		return view;
	}
	else if( [item isKindOfClass:[NSString class]] )
	{
		EXFriendsListRowView *view = [outlineView makeViewWithIdentifier:@"GroupCell" owner:self];
		//[view.imageView setImage:[NSImage imageNamed:@"avatar-default"]];
		[view.textField setStringValue:item];
		return view;
	}
	return nil;
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
