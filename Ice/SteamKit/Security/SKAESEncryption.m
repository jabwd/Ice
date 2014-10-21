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
#import <Security/Security.h>
#import "NSData_XfireAdditions.h"

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
		NSInteger rest = [data length] % 16;
		NSInteger multiple = (NSInteger)[data length] / 16;
		if( rest > 0 )
		{
			multiple++;
		}
		bytesSize = 16*multiple;
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

+ (NSData *)encryptPacketData:(NSData *)packetData key:(NSData *)key
{
	NSData *iv = [self generateRandomData:16];
	NSData *encryptedIV		= nil;
	SecKeyRef cryptoKey		= NULL;
	SecTransformRef encrypt = NULL;
	CFErrorRef error		= NULL;
	
	CFMutableDictionaryRef params = CFDictionaryCreateMutable(
															  kCFAllocatorDefault,
															  0,
															  &kCFTypeDictionaryKeyCallBacks,
															  &kCFTypeDictionaryValueCallBacks
															  );
	
	CFDictionarySetValue(params, kSecAttrKeyType, kSecAttrKeyTypeAES);
	cryptoKey	= SecKeyCreateFromData(params, (CFDataRef)key, &error);
	encrypt		= SecEncryptTransformCreate(cryptoKey, &error);
	
	SecTransformSetAttribute(encrypt, kSecTransformInputAttributeName, (CFDataRef)iv, &error);
	SecTransformSetAttribute(encrypt, kSecPaddingKey, kSecPaddingNone, &error);
	SecTransformSetAttribute(encrypt, kSecEncryptionMode, kSecModeECBKey, &error);
	SecTransformSetAttribute(encrypt, kSecIVKey, NULL, &error);
	
	encryptedIV = (NSData *)SecTransformExecute(encrypt, &error);
	if( error )
	{
		DLog(@"Encryption error: %@", (NSError *)error);
	}
	CFRelease(encrypt);
	encrypt = SecEncryptTransformCreate(cryptoKey, &error);
	[encryptedIV autorelease];
	encryptedIV = [[encryptedIV subdataWithRange:NSMakeRange(0, 16)] retain];
	SecTransformSetAttribute(encrypt, kSecTransformInputAttributeName, (CFDataRef)packetData, &error);
	SecTransformSetAttribute(encrypt, kSecPaddingKey, kSecPaddingPKCS7Key, &error);
	SecTransformSetAttribute(encrypt, kSecEncryptionMode, kSecModeCBCKey, &error);
	SecTransformSetAttribute(encrypt, kSecIVKey, (CFDataRef)iv, &error);
	
	NSData *result = (NSData *)SecTransformExecute(encrypt, &error);
	NSMutableData *final = [[NSMutableData alloc] initWithData:encryptedIV];
	[final appendData:result];
	[result release];
	
	// Cleanup
	[encryptedIV release];
	CFRelease(encrypt);
	CFRelease(cryptoKey);
	
	return [final autorelease];
}

+ (NSData *)decryptPacketData:(NSData *)packetData key:(NSData *)key
{
	// Parse the packet data in the 2 parts we want
	NSData *encryptedIV			= [packetData subdataWithRange:NSMakeRange(0, 16)];
	NSData *encryptedMessage	= [packetData subdataWithRange:NSMakeRange(16, [packetData length]-16)];
	
	CFErrorRef error = nil;
	CFMutableDictionaryRef params = CFDictionaryCreateMutable(
															  kCFAllocatorDefault,
															  0,
															  &kCFTypeDictionaryKeyCallBacks,
															  &kCFTypeDictionaryValueCallBacks
															  );
	
	CFDictionarySetValue(params, kSecAttrKeyType, kSecAttrKeyTypeAES);
	SecKeyRef cryptoKey			= SecKeyCreateFromData((CFDictionaryRef)params, (CFDataRef)key, &error);
	SecTransformRef decrypt		= NULL;
	
	decrypt = SecDecryptTransformCreate(cryptoKey, &error);
	if( error )
	{
		DLog(@"Error while creating decryption transform %@", (NSError *)error);
	}
	
	// Decrypt the encryptedIV with NoPadding/ECB
	SecTransformSetAttribute(decrypt, kSecPaddingKey, kSecPaddingNoneKey, &error);
	SecTransformSetAttribute(decrypt, kSecTransformInputAttributeName, (CFDataRef)encryptedIV, &error);
	SecTransformSetAttribute(decrypt, kSecEncryptionMode, kSecModeECBKey, &error);
	SecTransformSetAttribute(decrypt, kSecIVKey, NULL, &error);
	
	if( error )
	{
		DLog(@"Parameters error %@", (NSError *)error);
	}
	
	NSData *decryptedIV = (NSData *)SecTransformExecute(decrypt, &error);
	CFRelease(decrypt);
	decrypt = SecDecryptTransformCreate(cryptoKey, &error);
	
	// Decrypt the actual packet content with PKCS7/CBC
	SecTransformSetAttribute(decrypt, kSecPaddingKey, kSecPaddingPKCS7Key, &error);
	SecTransformSetAttribute(decrypt, kSecTransformInputAttributeName, (CFDataRef)encryptedMessage, &error);
	SecTransformSetAttribute(decrypt, kSecIVKey, (CFDataRef)decryptedIV, &error);
	SecTransformSetAttribute(decrypt, kSecEncryptionMode, kSecModeCBCKey, &error);
	
	if( error )
	{
		DLog(@"Parameters error %@", (NSError *)error);
	}
	
	NSData *decryptedMessage = (NSData *)SecTransformExecute(decrypt, &error);
	
	// Cleanup
	CFRelease(params);
	CFRelease(cryptoKey);
	CFRelease(decrypt);
	[decryptedIV release];
	
	return [decryptedMessage autorelease];
}

@end
