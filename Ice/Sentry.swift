//
//  SentryStore.swift
//  Ice
//
//  Created by Antwan van Houdt on 10/06/15.
//  Copyright (c) 2015 Exurion. All rights reserved.
//

import Cocoa

@objc class Sentry {
	var session: SKSession
	
	init(session: SKSession) {
		self.session = session
	}
	
	class func appSupportDirectory() -> String
	{
		var finalPath: String = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0] as String
		if let infoDictionary: NSDictionary = NSBundle.mainBundle().infoDictionary
		{
			let appName: String = infoDictionary["CFBundleExecutable"] as! String
			finalPath += "/" + appName
			var error: NSError?		= nil
			do {
				try NSFileManager.defaultManager().createDirectoryAtPath(finalPath, withIntermediateDirectories: true, attributes: nil)
			} catch let error1 as NSError {
				error = error1
			}
			if error != nil
			{
				print("Error while creating appsupport directory: \(error)")
				return "/tmp"
			}
		}
		return finalPath
	}
	
	class func cacheFolderPath() -> String
	{
		var finalPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as String
		if let infoDictionary: NSDictionary = NSBundle.mainBundle().infoDictionary
		{
			let bundleIdentifier = infoDictionary["CFBundleIdentifier"] as! String
			finalPath += "/" + bundleIdentifier
			do {
				try NSFileManager.defaultManager().createDirectoryAtPath(finalPath, withIntermediateDirectories: true, attributes: nil)
			} catch _ {
			}
		}
		return finalPath
	}
	
	func sentryPath(fileName: String) -> String
	{
		let appSupport: String = Sentry.appSupportDirectory() + "/" + self.session.username()
		do {
			try NSFileManager.defaultManager().createDirectoryAtPath(appSupport, withIntermediateDirectories: true, attributes: nil)
		} catch _ {
		}
		return appSupport + "/" + fileName
	}
	
	func fileName() -> String?
	{
		let key = "Sentry." + self.session.username()
		let anyObject: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(key)
		if anyObject != nil
		{
			return anyObject as? String
		}
		return nil
	}
	
	func currentSentryFilePath() -> String?
	{
		let path: String? = self.fileName()
		if path != nil
		{
			return self.sentryPath(path!)
		}
		return nil
	}
	
	func sha1Hash() -> NSData?
	{
		let path	= self.currentSentryFilePath()
		if path == nil
		{
			return nil
		}
		
		if NSFileManager.defaultManager().fileExistsAtPath(path!) == false
		{
			return nil
		}
		
		let fileData: NSData? = NSData.init(contentsOfFile: path!)
		if fileData == nil
		{
			return nil
		}
		
		let idx: CFIndex = 40
		let digestType: AnyObject = kSecDigestSHA1
		let digest: Unmanaged<SecTransform> = SecDigestTransformCreate(digestType, idx, nil)
		
		let result: NSData? = SecTransformExecute(digest as! AnyObject, nil) as? NSData
		if result != nil
		{
			return result
		}
		return nil
	}
	
	func exists() -> Bool
	{
		let hash: NSData? = self.sha1Hash()
		if hash == nil || hash?.length != 40
		{
			print("Corrupt or missing SteamGuard data file")
			return false
		}
		return true
	}
	
	func createWithData(bytes: NSData, fileName: String)
	{
		if bytes.length > 1
		{
			let path: String? = self.sentryPath(fileName)
			if path != nil
			{
				let key: String = "Sentry." + self.session.username()
				NSUserDefaults.standardUserDefaults().setObject(path, forKey: key)
				bytes.writeToFile(path!, atomically: false)
				return
			}
		}
		print("An error occurred while writing sentry to disk, corrupt data or filePath missing!")
	}
}