//
//  SKAESEncryption.m
//  Ice
//
//  Created by Antwan van Houdt on 24/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKAESEncryption.h"
#import <Security/Security.h>
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
	NSUInteger bytesSize = 128;
	
	// Determine how big our buffer needs to be to support the data we want to encrypt
	if( [data length] > 128 )
	{
		NSInteger rest = [data length] % 2;
		rest++;
		bytesSize = 128*rest;
		DLog(@"=> Using %lu as buffer size for AES encryption", bytesSize);
	}
	
	size_t bufferSize	= bytesSize + kCCBlockSizeAES128;
	size_t numBytesEncrypted;
    void *buffer		= malloc(bufferSize);
	
	// make sure the data buffer is of hte right size
	// append with 0's if needed.
	NSMutableData *finalData = [[NSMutableData alloc] initWithCapacity:bytesSize];
	if( [data length] < bytesSize )
	{
		NSUInteger missingBytes = bytesSize-[data length];
		[finalData appendData:data];
		char *bytes = (char*)malloc(sizeof(char)*missingBytes);
		memset(bytes, 0, missingBytes);
		[finalData appendBytes:bytes length:missingBytes];
		free(bytes);
		if( [finalData length] != bytesSize )
		{
			DLog(@"Finaldata buffer not equal size to the requested size, something went wrong with the padding.");
			[finalData release];
			free(buffer);
			return nil;
		}
	}
	
	CCCryptorStatus status = CCCrypt(
		kCCEncrypt,
		kCCAlgorithmAES128,
		kCCOptionPKCS7Padding,
		[key bytes],
		kCCKeySizeAES256,
		[iv bytes],
		[finalData bytes],
		[finalData length],
		buffer, bufferSize,
		&numBytesEncrypted
	);
	[finalData release];
	
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
