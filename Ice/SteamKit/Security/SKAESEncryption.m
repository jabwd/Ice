//
//  SKAESEncryption.m
//  Ice
//
//  Created by Antwan van Houdt on 24/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKAESEncryption.h"
#import <CommonCrypto/CommonCrypto.h>
#import <stdlib.h>

@implementation SKAESEncryption

+ (NSData *)generateRandomData:(NSUInteger)length
{
	NSMutableData *buffer = [[NSMutableData alloc] initWithCapacity:length];
	for(NSInteger i = 0;i<length;i++)
	{
		char byte = arc4random_uniform(255);
		[buffer appendBytes:&byte length:1];
	}
	return [buffer autorelease];
}

+ (NSData *)encryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv
{
	size_t bufferSize	= [data length] + kCCBlockSizeAES128;
	size_t numBytesEncrypted;
    void *buffer		= malloc(bufferSize);
	CCCryptorStatus status = CCCrypt(
		kCCEncrypt,
		kCCAlgorithmAES128,
		kCCOptionPKCS7Padding,
		[key bytes],
		kCCKeySizeAES256,
		[iv bytes],
		[data bytes],
		[data length],
		buffer, bufferSize,
		&numBytesEncrypted
	);
	
	if( status == kCCSuccess )
	{
		NSData *result = [[NSData alloc] initWithBytesNoCopy:buffer length:bufferSize];
		return [result autorelease];
	}
	free(buffer);
	return nil;
}

+ (NSData *)decryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv
{
	size_t bufferSize	= [data length] + kCCBlockSizeAES128;
	size_t numBytesEncrypted;
    void *buffer		= malloc(bufferSize);
	CCCryptorStatus status = CCCrypt(
									 kCCDecrypt,
									 kCCAlgorithmAES128,
									 kCCOptionPKCS7Padding,
									 [key bytes],
									 kCCKeySizeAES256,
									 [iv bytes],
									 [data bytes],
									 [data length],
									 buffer, bufferSize,
									 &numBytesEncrypted
									 );
	
	if( status == kCCSuccess )
	{
		NSData *result = [[NSData alloc] initWithBytesNoCopy:buffer length:bufferSize];
		return [result autorelease];
	}
	free(buffer);
	return nil;
}

@end
