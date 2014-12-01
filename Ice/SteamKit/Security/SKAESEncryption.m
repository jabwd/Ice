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
#import "NSData_SteamKitAdditions.h"

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

+ (NSData *)encryptPacketData:(NSData *)packetData key:(NSData *)key
{
	static NSData *iv = nil;
	if( !iv )
	{
		iv = [[self generateRandomData:16] retain];
	}
	if( !key )
	{
		return nil;
	}
	//NSData *iv				= [self generateRandomData:16];
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
	
	// Create the SecKeyRef and the cryptor for the IV
	CFDictionarySetValue(params, kSecAttrKeyType, kSecAttrKeyTypeAES);
	cryptoKey	= SecKeyCreateFromData(params, (CFDataRef)key, &error);
	encrypt		= SecEncryptTransformCreate(cryptoKey, &error);
	
	SecTransformSetAttribute(encrypt, kSecTransformInputAttributeName, (CFDataRef)iv, &error);
	SecTransformSetAttribute(encrypt, kSecPaddingKey, kSecPaddingNone, &error);
	SecTransformSetAttribute(encrypt, kSecEncryptionMode, kSecModeECBKey, &error);
	SecTransformSetAttribute(encrypt, kSecIVKey, NULL, &error);
	
	// Encrypt the IV for appeding to the front of the packet data
	encryptedIV = (NSData *)SecTransformExecute(encrypt, &error);
	if( error )
	{
		DLog(@"Encryption error: %@", (NSError *)error);
	}
	CFRelease(encrypt);
	
	// Create the cryptor for the packet data
	encrypt = SecEncryptTransformCreate(cryptoKey, &error);
	SecTransformSetAttribute(encrypt, kSecTransformInputAttributeName, (CFDataRef)packetData, &error);
	SecTransformSetAttribute(encrypt, kSecPaddingKey, kSecPaddingPKCS7Key, &error);
	SecTransformSetAttribute(encrypt, kSecEncryptionMode, kSecModeCBCKey, &error);
	SecTransformSetAttribute(encrypt, kSecIVKey, (CFDataRef)iv, &error);
	
	// Encrypt the packet data itselllf using the non-encrypted IV and AES/CBC/PKCS7
	NSData *result = (NSData *)SecTransformExecute(encrypt, &error);
	if( error )
	{
		DLog(@"Encryption error: %@", (NSError *)error);
	}
	
	// Generate the final data by appending the 16 byte encrypted IV to the front
	// of the encrypted packet data
	NSMutableData *final = [[NSMutableData alloc] initWithData:[encryptedIV subdataWithRange:NSMakeRange(0, 16)]];
	[final appendData:result];
	[result release];
	
	// Cleanup
	[encryptedIV release];
	CFRelease(encrypt);
	CFRelease(params);
	CFRelease(cryptoKey);
	
	return [final autorelease];
}

+ (NSData *)decryptPacketData:(NSData *)packetData key:(NSData *)key
{
	if( [packetData length] < 16 || !key)
	{
		return packetData;
	}
	
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
