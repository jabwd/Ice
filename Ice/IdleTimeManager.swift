//
//  IdleTimeManager.swift
//  Ice
//
//  Created by Antwan van Houdt on 11/08/15.
//  Copyright © 2015 Exurion. All rights reserved.
//

import Cocoa
import CoreGraphics
import ApplicationServices

@objc class IdleTimeManager: NSObject
{
	static let sharedManager: IdleTimeManager = IdleTimeManager()
	static let userWentAwayNotification: String = "UserWentAwayNotification"
	static let userCameBackNotification: String = "UserCameBackNotification"
	static let autoAwayTimeKey: String			= "autoGoAwayTime"
	static let shouldAutoAwayKey: String		= "autoGoAway"
	
	var isIdle: Bool?
	var setStatusAutomatically: Bool?
	var timer: NSTimer?
	var eventSource: CGEventSourceRef?
	
	override init()
	{
		super.init()
		
		setStatusAutomatically = NSUserDefaults.standardUserDefaults().boolForKey("autoGoAway")
		timer	= nil
		isIdle	= false
		
		if( setStatusAutomatically == true )
		{
			print("=> The AFK time has started and will check for the idle state soon")
			eventSource = CGEventSourceCreate(CGEventSourceStateID.CombinedSessionState)
			let time: NSTimeInterval = NSUserDefaults.standardUserDefaults().objectForKey("autoGoAwayTime")!.doubleValue
			print("=> The time used will be \(time)seconds")
			//timer  = NSTimer(timeInterval: time, target: self, selector: Selector("checkIdleState"), userInfo: nil, repeats: false)
			timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: Selector("checkIdleState:"), userInfo: nil, repeats: false)
		}
		else
		{
			print("=> The AFK timer did not start, user has disabled it")
		}
	}
	
	deinit
	{
		if timer != nil
		{
			timer!.invalidate()
			timer = nil
		}
		// I don't believe I also need to get rid of the eventSource
	}
	
	func setAwayStatusAutomatically(shouldSet: Bool)
	{
		setStatusAutomatically = shouldSet
		if( shouldSet == true )
		{
			eventSource = CGEventSourceCreate(CGEventSourceStateID.CombinedSessionState)
			let time: NSTimeInterval = NSUserDefaults.standardUserDefaults().objectForKey("autoGoAwayTime")!.doubleValue
			timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: Selector("checkIdleState:"), userInfo: nil, repeats: false)
		}
		else
		{
			if( timer != nil )
			{
				timer!.invalidate()
				timer = nil
			}
			eventSource = nil
		}
	}
	
	func checkIdleState(passedTimer: NSTimer)
	{
		print("=> Checking idle state")
		let time: NSTimeInterval	= NSUserDefaults.standardUserDefaults().objectForKey("autoGoAwayTime")!.doubleValue
		let seconds: NSTimeInterval = CGEventSourceSecondsSinceLastEventType(CGEventSourceStateID.CombinedSessionState, CGEventType.TapDisabledByUserInput)
		print("=> The user was idle for \(seconds)seconds")
		
		if( isIdle == true )
		{
			if( seconds <= time )
			{
				isIdle	= false
				
				NSNotificationCenter.defaultCenter().postNotificationName(IdleTimeManager.userCameBackNotification, object: self)
				if( timer != nil )
				{
					timer!.invalidate()
					timer = nil
				}
				timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("checkIdleState:"), userInfo: nil, repeats: false)
			}
			else
			{
				// do nothing atm.
			}
		}
		else
		{
			if( seconds >= time )
			{
				isIdle = true
				
				NSNotificationCenter.defaultCenter().postNotificationName(IdleTimeManager.userWentAwayNotification, object: self)
				if( timer != nil )
				{
					timer!.invalidate()
					timer = nil
				}
				timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("checkIdleState:"), userInfo: nil, repeats: true)
			}
			else
			{
				if( timer != nil )
				{
					timer!.invalidate()
					timer = nil
				}
				let diff: NSTimeInterval = (time - seconds)
				timer = NSTimer.scheduledTimerWithTimeInterval(diff, target: self, selector: Selector("checkIdleState:"), userInfo: nil, repeats: false)
			}
		}
	}
}