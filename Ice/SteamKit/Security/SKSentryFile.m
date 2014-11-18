//
//  SKSentryFile.m
//  Ice
//
//  Created by Antwan van Houdt on 14/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKSentryFile.h"
#import <Security/Security.h>
#import "SKFriend.h"
#import "SKSteamID.h"
#import "SKSession.h"

@implementation SKSentryFile

+ (NSString *)appSupportDirectory
{
	static NSString *finalPath = nil;
	if( finalPath )
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:nil];
		return finalPath;
	}
	NSArray *paths = NSSearchPathForDirectoriesInDomains(
		NSApplicationSupportDirectory,
		NSUserDomainMask,
		YES
	);
	
	if( [paths count] == 0 )
	{
		NSLog(@"Error: cannot find AppSupport directory to store steam guard file!");
		return nil;
	}
	
	NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	NSString *appSupport = paths[0];
	if( [executableName length] == 0 )
	{
		NSLog(@"Error: unable to find application executable name");
		return nil;
	}
	
	finalPath = [[appSupport stringByAppendingPathComponent:executableName] retain];
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:&error];
	if( error )
	{
		NSLog(@"Unable to create AppSupport directory");
		return nil;
	}
	return finalPath;
}

+ (NSString *)cacheFolderPath
{
	static NSString *finalPath = nil;
	if( finalPath )
	{
		return finalPath;
	}
	NSArray *paths = NSSearchPathForDirectoriesInDomains(
														 NSCachesDirectory,
														 NSUserDomainMask,
														 YES
														 );
	
	if( [paths count] == 0 )
	{
		DLog(@"Cannot find cache folder path");
		return nil;
	}
	
	NSString *domain = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	
	finalPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:domain] retain];
	[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:nil];
	return finalPath;
}

- (id)initWithSession:(SKSession *)session
{
	if( (self = [super init]) )
	{
		_session = session;
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	_data = nil;
	_session = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (NSString *)sentryPath:(NSString *)fileName
{
	NSString *appSupport = [SKSentryFile appSupportDirectory];
	appSupport = [appSupport stringByAppendingPathComponent:[_session username]];
	[[NSFileManager defaultManager] createDirectoryAtPath:appSupport withIntermediateDirectories:YES attributes:nil error:nil];
	return [appSupport stringByAppendingPathComponent:fileName];
}

- (NSString *)fileName
{
	NSString *key = [NSString stringWithFormat:@"Sentry.%@", [_session username]];
	return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (NSString *)currentSentryFilePath
{
	NSString *fileName = [self fileName];
	if( !fileName )
	{
		return nil;
	}
	return [self sentryPath:fileName];
}

- (NSData *)sha1Hash
{
	
	NSString *path = [self currentSentryFilePath];
	NSFileManager *manager = [NSFileManager defaultManager];
	if( ![manager fileExistsAtPath:path] )
	{
		return nil;
	}
	NSData *fileData = [[NSData alloc] initWithContentsOfFile:path];
	if( !fileData )
	{
		return nil;
	}
	
	SecTransformRef digest;
	CFErrorRef error;
	
	digest = SecDigestTransformCreate(kSecDigestSHA1, 40, &error);
	SecTransformSetAttribute(digest, kSecTransformInputAttributeName, (CFDataRef)fileData, &error);
	
	NSData *result = (NSData *)SecTransformExecute(digest, &error);
	if( error )
	{
		DLog(@"Error while hashing SteamGuard file: %@", (NSError *)error);
	}
	
	// Cleanup
	CFRelease(digest);
	[fileData release];
	
	return [result autorelease];
}

- (BOOL)exists
{
	NSData *hash = [self sha1Hash];
	if( [hash length] != 40 )
	{
		DLog(@"Corrupt or non existing SteamGuard data file");
		return NO;
	}
	return YES;
}

- (void)createWithData:(NSData *)bytes fileName:(NSString *)fileName
{
	if( [bytes length] > 1 )
	{
		NSString *path = [self sentryPath:fileName];
		[[NSUserDefaults standardUserDefaults] setObject:fileName forKey:[NSString stringWithFormat:@"Sentry.%@", [_session username]]];
		[bytes writeToFile:path atomically:NO];
	}
	else
	{
		DLog(@"Not enough bytes to write sentry file %lu", [bytes length]);
	}
}

@end
