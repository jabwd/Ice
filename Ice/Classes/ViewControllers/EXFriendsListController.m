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
#import "BFNotificationCenter.h"

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
												 selector:@selector(reloadData:)
													 name:SKFriendsListChangedNotificationName
												   object:_session];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(openChat:)
													 name:SKFriendNeedsChatWindowNotificationName
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(onlineStatusChanged:)
													 name:SKFriendOnlineStatusChangedNotification
												   object:nil];
		
		[self performSelector:@selector(activateNotifications) withObject:nil afterDelay:5.0f];
		_notifications = NO;
	}
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
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

- (void)setSession:(SKSession *)session
{
	[_session release];
	_session = session;
	
	if( _session == nil )
	{
		for(EXChatWindowController *controller in _chatWindowControllers)
		{
			[controller goOffline];
		}
	}
	
	[self reloadData:nil];
}

- (SKFriend *)newRemoteFriendForID:(SKSteamID *)steamID
{
	return nil;
}

- (void)reloadData:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if( notification.userInfo )
		{
			SKFriend *fr = notification.userInfo[@"remoteFriend"];
			NSInteger row = [_outlineView rowForItem:fr];
			if( row > 0 )
			{
				[_outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
										columnIndexes:[NSIndexSet indexSetWithIndex:0]];
			}
		}
		[_outlineView reloadData];
	});
}

- (void)activateNotifications
{
	_notifications = YES;
}

- (void)onlineStatusChanged:(NSNotification *)notification
{
	if( !_notifications )
	{
		return;
	}
	
	SKFriend *remoteFriend = notification.object;
	if( remoteFriend )
	{
		if( remoteFriend.status != SKPersonaStateOffline )
		{
			NSString *message = [NSString stringWithFormat:@"%@ is now online", [remoteFriend displayNameString]];
			[[BFNotificationCenter defaultNotificationCenter] postNotificationWithTitle:@"Friend came online" body:message];
			[[BFNotificationCenter defaultNotificationCenter] playOnlineSound];
		}
		else
		{
			NSString *message = [NSString stringWithFormat:@"%@ went offline", [remoteFriend displayNameString]];
			[[BFNotificationCenter defaultNotificationCenter] postNotificationWithTitle:@"Friend went offline" body:message];
			[[BFNotificationCenter defaultNotificationCenter] playOfflineSound];
		}
	}
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SKFriend *selFriend = [self selectedFriend];
	if( selFriend )
	{
		if( [menuItem tag] == 1 )
		{
			if( selFriend.isPendingFriend )
			{
				[menuItem setTitle:@"Accept friend request"];
			}
			else
			{
				[menuItem setTitle:@"Remove friend"];
			}
		}
		return YES;
	}
	return NO;
}

- (SKFriend *)selectedFriend
{
	SKFriend *item = [_outlineView itemAtRow:[self activeRow]];
	if( [item isKindOfClass:[SKFriend class]] )
	{
		return item;
	}
	return nil;
}

- (NSInteger)activeRow
{
	// first check the selected row
	NSInteger selRow    = [_outlineView selectedRow];
	NSInteger clickRow  = [_outlineView clickedRow];
	
	if ( selRow == clickRow )
		return selRow;
	else if ( clickRow >= 0 )
		return clickRow;
	else
		return selRow;
	return 0;
}

#pragma mark - Friend menu

- (IBAction)removeFriend:(id)sender
{
	SKFriend *fr = [self selectedFriend];
	if( fr )
	{
		// this method handles both situations as the menu item
		// gets modified depending on the situation
		if( fr.isPendingFriend )
		{
			[fr addAsFriend];
		}
		else
		{
			[fr removeAsFriend];
		}
	}
}

- (IBAction)blockFriend:(id)sender
{
	NSBeep();
}

- (IBAction)showProfile:(id)sender
{
	SKFriend *sel = [self selectedFriend];
	NSString *URL = [NSString stringWithFormat:@"http://steamcommunity.com/profiles/%llu", sel.steamID.rawSteamID];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL]];
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
		[self performSelector:@selector(openGroups) withObject:nil afterDelay:1.0f];
		if( [_session.pendingFriends count] > 0 )
		{
			return 3;
		}
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
	else if( [item isEqualToString:EXPendingFriendsGroupName] )
	{
		return [_session.pendingFriends count];
	}
	return 0;
}

- (void)openGroups
{
	[_outlineView expandItem:EXOnlineFriendsGroupName];
	[_outlineView expandItem:EXOfflineFriendsGroupName];
	if( _session.pendingFriends )
	{
		[_outlineView expandItem:EXPendingFriendsGroupName];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if( item == nil )
	{
		if( index == 0 )
		{
			return EXOnlineFriendsGroupName;
		}
		else if( index == 1 )
		{
			return EXOfflineFriendsGroupName;
		}
		else if( index == 2 )
		{
			return EXPendingFriendsGroupName;
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
	else if( [item isEqualToString:EXPendingFriendsGroupName] )
	{
		return _session.pendingFriends[index];
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
		[view setAvatarImage:[remoteFriend avatarImage]];
		[view.textField setStringValue:[remoteFriend displayNameString]];
		
		if( remoteFriend.status != SKPersonaStateOnline || remoteFriend.appID != 0 )
		{
			[view setShowsStatusField:YES];
			[view.statusField setStringValue:[remoteFriend statusDisplayString]];
		}
		else if( remoteFriend.isPendingFriend )
		{
			[view setShowsStatusField:YES];
			[view.statusField setStringValue:[remoteFriend statusDisplayString]];
		}
		else
		{
			[view setShowsStatusField:NO];
			[view.statusField setStringValue:@""];
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
	if( [item isKindOfClass:[NSString class]] )
	{
		return nil;
	}
	NSInteger row = [outlineView rowForItem:item];
	if( row > 0 )
	{
		NSTableRowView *rowView = [outlineView rowViewAtRow:row makeIfNecessary:YES];
		if( rowView )
		{
			return rowView;
		}
	}
	return nil;
}

@end
