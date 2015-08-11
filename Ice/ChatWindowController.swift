//
//  ChatWindowController.swift
//  Ice
//
//  Created by Antwan van Houdt on 06/08/15.
//  Copyright © 2015 Exurion. All rights reserved.
//

import Cocoa

protocol ChatWindowControllerDelegate
{
	func shouldCloseController(controller: ChatWindowController)
	func newRemoteFriendForID(steamId: SteamID) -> SKFriend
}

enum ChatMessageType
{
	case User
	case RemoteFriend
	case Notification
}

@objc class ChatWindowController: NSWindowController, SKFriendChatDelegate, NSWindowDelegate, BFChatMessageViewDelegate
{
	var remoteFriend:		SKFriend
	var delegate:			ChatWindowControllerDelegate?
	var previousTime:		UInt?
	var missedMsgsCount:	UInt?
	
	@IBOutlet weak var messageView:		XNResizingMessageView?
	@IBOutlet weak var textView:		NSTextView?
	@IBOutlet weak var isTypingView:	NSImageView?
	@IBOutlet weak var stripView:		SFTabStripView?
	
	override init(window: NSWindow!)
	{
		self.remoteFriend = SKFriend()
		super.init(window: window)
	}
	
	convenience init(remoteFriend: SKFriend)
	{
		self.init(windowNibName: "EXChatWindowController")
		self.remoteFriend			= remoteFriend
		self.previousTime			= 0
		self.missedMsgsCount		= 0
		self.remoteFriend.delegate	= self
	}

	required init?(coder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}
	
	func windowShouldClose(sender: AnyObject) -> Bool
	{
		remoteFriend.delegate = nil
		delegate!.shouldCloseController(self)
		return true
	}
	
	override func windowDidLoad()
	{
		super.windowDidLoad()
		
		if( self.window == nil )
		{
			return;
		}
		let chatWindow: NSWindow = window!
		
		chatWindow.title = "Chat - " + remoteFriend.displayNameString()
		chatWindow.setContentBorderThickness(35.0, forEdge: NSRectEdge.MinY)
		chatWindow.setAutorecalculatesContentBorderThickness(false, forEdge: NSRectEdge.MinY)
		
	}
	
	func windowDidBecomeKey(notification: NSNotification) {
		
	}
	
	func controlTextChanged()
	{
		
	}
	
	func resizeMessageView(messageView: AnyObject!)
	{
		
	}
	
	func friendDidReceiveMessage(message: String!, date: NSDate!, type entryType: SKChatEntryType) {
		
	}
	
	func friendStatusDidChange() {
		
	}
	
	func goOffline()
	{
		messageView!.enabled = false
	}
	
	func sendMessage(message: String!)
	{
		previousTime = 0
		//remoteFriend.sendMessage(message, ofType: 1 as SKChatEntryType)
	}
}
