//
//  SteamId.swift
//  Ice
//
//  Created by Antwan van Houdt on 06/08/15.
//  Copyright © 2015 Exurion. All rights reserved.
//

import Foundation

@objc class SteamID: NSObject
{
	var rawSteamID: UInt64
	
	init(rawSteamID: UInt64)
	{
		self.rawSteamID = rawSteamID
	}
	
	func accountID() -> UInt32
	{
		return UInt32(rawSteamID & 0xFFFFFFFF)
	}
	
	func instance() -> UInt32
	{
		return UInt32((rawSteamID >> 32) & 0x000FFFFF)
	}
	
	func type() -> UInt32
	{
		return UInt32((rawSteamID >> 52) & 0xF)
	}
	
	func universe() -> UInt32
	{
		return UInt32((rawSteamID >> 56) & 0xF)
	}
	
	override var description: String
	{
		return "[SteamId type=\(type()) id=\(accountID()) uni=\(universe())]"
	}
}