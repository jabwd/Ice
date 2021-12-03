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
	return [_sentry sha1Hash];
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
