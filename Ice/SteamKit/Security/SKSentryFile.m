//
//  SKSentryFile.m
//  Ice
//
//  Created by Antwan van Houdt on 14/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKSentryFile.h"
#import <Security/Security.h>

@implementation SKSentryFile

+ (NSString *)appSupportDirectory
{
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
	
	NSString *finalPath = [appSupport stringByAppendingPathComponent:executableName];
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:&error];
	if( error )
	{
		NSLog(@"Unable to create AppSupport directory");
		return nil;
	}
	return finalPath;
}

- (id)init
{
	if( (self = [super init]) )
	{
		//_data = [[NSData alloc] initWithContentsOfFile:[self currentSentryFilePath]];
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	_data = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (NSString *)sentryPath:(NSString *)fileName
{
	NSString *appSupport = [SKSentryFile appSupportDirectory];
	return [appSupport stringByAppendingPathComponent:fileName];
}

- (NSString *)fileName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"SentryFileName"];
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
		[[NSUserDefaults standardUserDefaults] setObject:fileName forKey:@"SentryFileName"];
		[bytes writeToFile:path atomically:NO];
	}
	else
	{
		DLog(@"Not enough bytes to write sentry file %lu", [bytes length]);
	}
}

@end
