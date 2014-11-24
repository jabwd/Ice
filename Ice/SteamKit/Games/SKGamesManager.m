//
//  SKGamesManager.m
//  Ice
//
//  Created by Antwan van Houdt on 23/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKGamesManager.h"
#import "SKSentryFile.h"
#import "SKSession.h"

@implementation SKGamesManager

+ (instancetype)sharedManager
{
	static SKGamesManager *gamesManager = nil;
	if( ! gamesManager )
	{
		gamesManager = [[SKGamesManager alloc] init];
	}
	return gamesManager;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_cache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_cache release];
	_cache = nil;
	[super dealloc];
}

- (void)downloadImageAtURL:(NSURL *)URL forID:(UInt32)appID
{
	NSString *finalPath = [[SKSentryFile cacheFolderPath] stringByAppendingPathComponent:@"games"];
	[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:nil];
	finalPath = [finalPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.ico", appID]];
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		if( !error )
		{
			DLog(@"=> Downloaded image for %@", URL);
			[data writeToFile:finalPath atomically:YES];
			[[NSNotificationCenter defaultCenter] postNotificationName:SKFriendsListChangedNotificationName
																object:nil];
		}
		else
		{
			DLog(@"[Error] image download failed %@", error);
		}
	}];
	[request release];
}

- (NSImage *)imageForAppID:(UInt32)appID
{
	// See if we encountered this image before hand
	NSString *key = [NSString stringWithFormat:@"%u", appID];
	if( _cache[key] )
	{
		return _cache[key];
	}
	
	NSString *path	= [[SKSentryFile cacheFolderPath] stringByAppendingPathComponent:@"games"];
	path			= [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.ico", appID]];
	if( [[NSFileManager defaultManager] fileExistsAtPath:path] )
	{
		NSImage *theImage = [[NSImage alloc] initWithContentsOfFile:path];
		if( !theImage )
		{
			return nil;
		}
		_cache[key] = theImage;
		return [theImage autorelease];
	}
	return nil; // this allows the other part of the code to respond and request
	// the image download to begin.
}

@end
