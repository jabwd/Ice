//
//  SKSentryFile.h
//  Ice
//
//  Created by Antwan van Houdt on 14/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKSentryFile : NSObject
{
	NSData *_data;
}
@property (retain) NSData *data;

/**
 * Finds or creates the AppSupport directory for the current app
 *
 * @return NSString		appSupport directory path
 */
+ (NSString *)appSupportDirectory;

/**
 * Returns the path to the SteamGuard.dat file in the appsupport directory
 * or nil if it does not exist
 *
 * @return NSString		path to the sentry file
 */
- (NSString *)sentryPath:(NSString *)fileName;

/**
 * Returns the hashed content of the sentry file
 * for use in the login sequence
 * ( uses sha-1 )
 *
 * @return NSData		the 40 byte hash
 */
- (NSData *)sha1Hash;

/**
 * Verifies whether there is a valid steamGuard file on the computer
 * at this time
 *
 * @return BOOL		wwhether a valid SteamGuard file exists or not
 */
- (BOOL)exists;

/**
 * Overwrites the current steamGuard file with the given bytes
 *
 * @param NSData		the bytes to put in the content of the steamGuard file
 *
 * @return void
 */
- (void)createWithData:(NSData *)bytes fileName:(NSString *)fileName;

@end
