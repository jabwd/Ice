//
//  BorderedScrollView.swift
//  Ice
//
//  Created by Antwan van Houdt on 10/08/15.
//  Copyright © 2015 Exurion. All rights reserved.
//

import Cocoa

@objc class BorderedScrollView: NSScrollView
{
	var offlineMode: Bool?
	override var opaque: Bool { get { return false } }
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BorderedScrollView.update), name: NSWindowDidBecomeKeyNotification, object: self.window)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BorderedScrollView.update), name: NSWindowDidResignKeyNotification, object: self.window)
	}
	
	deinit
	{
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	override func drawRect(dirtyRect: NSRect)
	{
		let frame: NSRect = self.bounds
		var alpha: CGFloat = 1.0
		if self.offlineMode == true
		{
			alpha = 0.5
		}
		
		let path: NSBezierPath = NSBezierPath(roundedRect: NSMakeRect(frame.origin.x+0.5, frame.origin.y+0.5, frame.size.width-1, frame.size.height), xRadius: 5, yRadius: 5)
		NSColor(calibratedWhite: 1.0, alpha: alpha).set()
		path.fill()
		let path2 = NSBezierPath(roundedRect: NSMakeRect(frame.origin.x+0.5, frame.origin.y+0.5, frame.size.width-1, frame.size.height), xRadius: 5, yRadius: 5)
		path2.lineWidth = 1.0
		
		if self.window?.keyWindow == true
		{
			NSColor(calibratedWhite: 0.6, alpha: alpha).set()
		}
		else
		{
			NSColor(calibratedWhite:0.7, alpha: alpha).set()
		}
		path2.stroke()
	}
	
	func update()
	{
		self.needsDisplay = true
	}
}
