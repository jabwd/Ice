//
//  BFIdleTimeManager.m
//  BlackFire
//
//  Created by Mark Douma on 1/31/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "BFIdleTimeManager.h"

static BFIdleTimeManager *sharedManager = nil;



@implementation BFIdleTimeManager
{
	NSTimer				*timer;
	CGEventSourceRef	eventSourceRef;
	
	BOOL              isIdle;
	BOOL              setAwayStatusAutomatically;
	
}

+ (BFIdleTimeManager *)defaultManager 
{
	if (sharedManager == nil) {
		sharedManager = [[self alloc] init];
	}
	return sharedManager;
}

- (id)init 
{
	if( (self = [super init]) ) 
	{
		setAwayStatusAutomatically = [[NSUserDefaults standardUserDefaults] boolForKey:@"autoGoAway"];
		timer = nil;
		eventSourceRef = NULL;
		isIdle = NO;
		
		if (setAwayStatusAutomatically) 
		{
			if (eventSourceRef == NULL) 
			{
				eventSourceRef = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
			}
			unsigned short time = [[[NSUserDefaults standardUserDefaults] objectForKey:@"autoGoAwayTime"] intValue];
			timer = [NSTimer scheduledTimerWithTimeInterval:time
													 target:self
												   selector:@selector(checkIdleState:)
												   userInfo:nil
													repeats:NO];
		}
	}
	return self;
}


- (void)dealloc {
	[timer invalidate];
	timer = nil;
	if (eventSourceRef != NULL) {
		CFRelease(eventSourceRef);
	}
	
	[super dealloc];
}


- (void)checkIdleState:(NSTimer *)aTimer {
	unsigned short time = [[[NSUserDefaults standardUserDefaults] objectForKey:@"autoGoAwayTime"] intValue];
	//time = (time * 60.0);
	NSTimeInterval seconds = (NSTimeInterval)CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
	
	
	if (isIdle) 
	{
		if (seconds <= time) {
			[timer invalidate];
			timer = nil;
			isIdle = NO;
			/*	[[NSNotificationCenter defaultCenter] postNotificationName:BFUserDidBecomeActiveNotification
			 object:nil
			 userInfo:nil];*/
			[_delegate userBecameActive];
			
			timer = [NSTimer scheduledTimerWithTimeInterval:2.0
													 target:self
												   selector:@selector(checkIdleState:)
												   userInfo:nil
													repeats:NO];
		} else {
			
		}
		
		
	} else {
		if (seconds >= time) {
			isIdle = YES;
			/*[[NSNotificationCenter defaultCenter] postNotificationName:BFUserDidBecomeIdleNotification 
			 object:nil
			 userInfo:nil];*/
			
			[_delegate userWentAway];
			
			// previous non-repeating timer is invalidated automatically
			timer = [NSTimer scheduledTimerWithTimeInterval:2.0
													 target:self
												   selector:@selector(checkIdleState:)
												   userInfo:nil
													repeats:YES];
		} else {
			NSTimeInterval difference = (time - seconds);
			
			timer = [NSTimer scheduledTimerWithTimeInterval:difference
													 target:self
												   selector:@selector(checkIdleState:)
												   userInfo:nil
													repeats:NO];
			
		}
		
	}
	
	
}




- (void)setSetAwayStatusAutomatically:(BOOL)shouldSetAutomatically
{
	if (shouldSetAutomatically)
	{
		setAwayStatusAutomatically = YES;
		if (eventSourceRef == NULL)
		{
			eventSourceRef = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
		}
		unsigned short time = [[[NSUserDefaults standardUserDefaults] objectForKey:@"autoGoAwayTime"] intValue];
		timer = [NSTimer scheduledTimerWithTimeInterval:time
												 target:self
											   selector:@selector(checkIdleState:)
											   userInfo:nil
												repeats:NO];
		isIdle = NO;
	}
	else
	{
		setAwayStatusAutomatically = NO;
		[timer invalidate];
		timer = nil;
		if (eventSourceRef != NULL)
		{
			CFRelease(eventSourceRef);
			eventSourceRef = NULL;
		}
	}
}


@end








