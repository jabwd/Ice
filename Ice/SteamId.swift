//
//  SteamId.swift
//  Ice
//
//  Created by Antwan van Houdt on 06/08/15.
//  Copyright © 2015 Exurion. All rights reserved.
//

import Foundation

@objc class SteamId: NSObject
{
	var rawSteamId: UInt64
	
	init(rawSteamId: UInt64)
	{
		self.rawSteamId = rawSteamId
	}
	
	func accountId() -> UInt32
	{
		return UInt32(rawSteamId & 0xFFFFFFFF)
	}
	
	func instance() -> UInt32
	{
		return UInt32((rawSteamId >> 32) & 0x000FFFFF)
	}
	
	func type() -> UInt32
	{
		return UInt32((rawSteamId >> 52) & 0xF)
	}
	
	func universe() -> UInt32
	{
		return UInt32((rawSteamId >> 56) & 0xF)
	}
	
	override var description: String
	{
		return "[SteamId type=\(type()) id=\(accountId()) uni=\(universe())]"
	}
}