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
	func newRemoteFriendForID(steamId: SKSteamID) -> SKFriend
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
	var delegate:			ChatWindowControllerDelegate
	var previousTime:		UInt
	var missedMsgsCount:	UInt
	
	
	init(remoteFriend: SKFriend)
	{
		self.remoteFriend			= remoteFriend
		self.remoteFriend.delegate	= self
	}

	required init?(coder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}
	
	func windowShouldClose(sender: AnyObject) -> Bool
	{
		remoteFriend.delegate = nil
		delegate.shouldCloseController(self)
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
}
