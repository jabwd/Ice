//
//  BFNotificationCenter.m
//  BlackFire
//
//  Created by Antwan van Houdt on 11/28/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#import "BFNotificationCenter.h"
#import "BFSoundSet.h"

static BFNotificationCenter *notificationCenter = nil;

NSString *BFSoundSetPathDefaultsKey		= @"defaultSoundSetPath";
NSString *BFSoundVolumeDefaultsKey		= @"soundVolume";

@implementation BFNotificationCenter
{
	NSMutableDictionary *_remoteFriends;
	
	NSSound *_connectSound;
	NSSound *_onlineSound;
	NSSound *_offlineSound;
	NSSound *_receiveSound;
	NSSound *_sendSound;
	
	NSUInteger _badgeCount;
}

+ (id)defaultNotificationCenter
{
	if( ! notificationCenter )
	{
		notificationCenter = [[[self class] alloc] init];
	}
	return notificationCenter;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_remoteFriends = [[NSMutableDictionary alloc] init];
		
		if( [[NSUserDefaults standardUserDefaults] objectForKey:BFSoundSetPathDefaultsKey] )
		{
			BFSoundSet *soundSet = [[BFSoundSet alloc] initWithContentsOfFile:[[NSUserDefaults standardUserDefaults] objectForKey:BFSoundSetPathDefaultsKey]];
			[self setSoundSet:soundSet];
			[soundSet release];
		}
	}
	return self;
}

- (void)dealloc
{
	[_remoteFriends release];
	_remoteFriends = nil;
	[_connectSound release];
	_connectSound = nil;
	[_sendSound release];
	_sendSound = nil;
	[_receiveSound release];
	_receiveSound = nil;
	[_offlineSound release];
	_offlineSound = nil;
	[_onlineSound release];
	_onlineSound = nil;
	
	[super dealloc];
}

#pragma mark - Handling sounds

- (void)setSoundSet:(BFSoundSet *)soundSet
{
	[_remoteFriends release];
	_remoteFriends = nil;
	[_connectSound release];
	_connectSound = nil;
	[_sendSound release];
	_sendSound = nil;
	[_receiveSound release];
	_receiveSound = nil;
	[_offlineSound release];
	_offlineSound = nil;
	[_onlineSound release];
	_onlineSound = nil;
	
	if( soundSet.connectedSoundPath )
	{
		_connectSound = [[NSSound alloc] initWithContentsOfFile:soundSet.connectedSoundPath byReference:NO];
	}
	
	if( soundSet.offlineSoundPath )
	{
		_offlineSound = [[NSSound alloc] initWithContentsOfFile:soundSet.offlineSoundPath byReference:NO];
	}
	
	if( soundSet.onlineSoundPath )
	{
		_onlineSound = [[NSSound alloc] initWithContentsOfFile:soundSet.onlineSoundPath byReference:NO];
	}
	
	if( soundSet.sendSoundPath )
	{
		_sendSound = [[NSSound alloc] initWithContentsOfFile:soundSet.sendSoundPath byReference:NO];
	}
	
	if( soundSet.receiveSoundPath )
	{
		_receiveSound = [[NSSound alloc] initWithContentsOfFile:soundSet.receiveSoundPath byReference:NO];
	}
	[self updateSoundVolume];
}

- (CGFloat)soundVolume
{
	return ([[NSUserDefaults standardUserDefaults] floatForKey:BFSoundVolumeDefaultsKey]/100);
}

- (void)updateSoundVolume
{
	CGFloat volume = [self soundVolume];
	
	_sendSound.volume		= volume;
	_receiveSound.volume	= volume;
	_onlineSound.volume		= volume;
	_offlineSound.volume	= volume;
	_connectSound.volume	= volume;
}

- (void)playDemoSound
{
	if( _connectSound )
		[self playConnectedSound];
	else if( _onlineSound )
		[self playOnlineSound];
	else if( _sendSound )
		[self playSendSound];
	else if( _offlineSound )
		[self playOfflineSound];
	else if( _receiveSound )
		[self playReceivedSound];
	else
		NSBeep();
}

- (void)playConnectedSound
{
	//if( ![[NSUserDefaults standardUserDefaults] boolForKey:BFEnableConnectSound] )
	//	return;
	
	if( ! _connectSound )
	{
		_connectSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"connected" ofType:@"m4v"] byReference:NO];
		_connectSound.volume = [self soundVolume];
	}
	if( [_connectSound isPlaying] )
	{
		[_connectSound stop];
	}
	[_connectSound play];
}


- (void)playOnlineSound
{
	//if( ![[NSUserDefaults standardUserDefaults] boolForKey:BFEnableFriendOnlineStatusSound] )
	//	return;
	
	if( ! _onlineSound )
	{
		_onlineSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"online" ofType:@"m4v"] byReference:NO];
		_onlineSound.volume = [self soundVolume];
	}
	if( [_onlineSound isPlaying] )
	{
		[_onlineSound stop];
	}
	
	[_onlineSound play];
}


- (void)playOfflineSound
{
	//if( ![[NSUserDefaults standardUserDefaults] boolForKey:BFEnableFriendOnlineStatusSound] )
	//	return;
	
	if( ! _offlineSound )
	{
		_offlineSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"offline" ofType:@"m4v"] byReference:NO];
		_offlineSound.volume = [self soundVolume];
	}
	if( [_offlineSound isPlaying] )
	{
		[_offlineSound stop];
	}
	
	[_offlineSound play];
}


- (void)playReceivedSound
{
	//if( ![[NSUserDefaults standardUserDefaults] boolForKey:BFEnableReceiveSound] )
	//	return;
	
	if( ! _receiveSound )
	{
		_receiveSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"receive" ofType:@"m4v"] byReference:NO];
		_receiveSound.volume = [self soundVolume];
	}
	
	if( [_receiveSound isPlaying] )
	{
		[_receiveSound stop];
	}
	
	[_receiveSound play];
}


- (void)playSendSound
{
	//if( ![[NSUserDefaults standardUserDefaults] boolForKey:BFEnableSendSound] )
	//	return;
	
	if( ! _sendSound )
	{
		_sendSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"send" ofType:@"m4v"] byReference:NO];
		_sendSound.volume = [self soundVolume];
	}
	if( [_sendSound isPlaying] )
		[_sendSound stop];
	
	[_sendSound play];
}


#pragma mark - Growl

- (void)postNotificationWithTitle:(NSString *)notificationTitle body:(NSString *)body
{
	[self postNotificationWithTitle:notificationTitle body:body context:nil];
}

- (void)postNotificationWithTitle:(NSString *)notificationTitle body:(NSString *)body context:(id)context
{
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	notification.title = notificationTitle;
	notification.informativeText = body;
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
	[notification release];
}

#pragma mark - Badge count

- (void)addBadgeCount:(NSUInteger)add
{
	_badgeCount += add;
	
	[[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", _badgeCount]];
}

- (void)deleteBadgeCount:(NSUInteger)remove
{
	_badgeCount -= remove;
	
    // update the badge, remove if smaller or equal than 0
	if( _badgeCount <= 0 )
	{
		[[NSApp dockTile] setBadgeLabel:nil];
        _badgeCount = 0;
	}
	else
	{
		[[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", _badgeCount]];
	}
}
@end
