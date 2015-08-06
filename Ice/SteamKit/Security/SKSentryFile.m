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

#import "Ice-Swift.h"

@implementation SKSentryFile

+ (NSString *)appSupportDirectory
{
	return [Sentry appSupportDirectory];
}

+ (NSString *)cacheFolderPath
{
	return [Sentry cacheFolderPath];
}

- (id)initWithSession:(SKSession *)session
{
	if( (self = [super init]) )
	{
		_sentry = [[Sentry alloc] initWithSession:session];
		_session = session;
	}
	return self;
}

- (void)dealloc
{
	[_sentry release];
	_sentry = nil;
	[_data release];
	_data = nil;
	_session = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (NSString *)sentryPath:(NSString *)fileName
{
	if( fileName )
	{
		return [_sentry sentryPath:fileName];
	}
	return nil;
}

- (NSString *)fileName
{
	return [_sentry fileName];
}

- (NSString *)currentSentryFilePath
{
	return [_sentry currentSentryFilePath];
}

- (NSData *)sha1Hash
{
	//return [_sentry sha1Hash];
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
	return [_sentry exists];
}

- (void)createWithData:(NSData *)bytes fileName:(NSString *)fileName
{
	if( !bytes || !fileName )
	{
		return;
	}
	return [_sentry createWithData:bytes fileName:fileName];
}

@end
