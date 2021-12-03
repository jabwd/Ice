//
//  SKRSAEncryption.m
//  Ice
//
//  Created by Antwan van Houdt on 25/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKRSAEncryption.h"
#import "NSData_SteamKitAdditions.h"
#import <Security/Security.h>
#import "SKPacket.h"

static const unsigned char steamPublicKey2014[] = {
		0x30, 0x81, 0x9D, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01,
		0x05, 0x00, 0x03, 0x81, 0x8B, 0x00, 0x30, 0x81, 0x87, 0x02, 0x81, 0x81, 0x00, 0xDF, 0xEC, 0x1A,
		0xD6, 0x2C, 0x10, 0x66, 0x2C, 0x17, 0x35, 0x3A, 0x14, 0xB0, 0x7C, 0x59, 0x11, 0x7F, 0x9D, 0xD3,
		0xD8, 0x2B, 0x7A, 0xE3, 0xE0, 0x15, 0xCD, 0x19, 0x1E, 0x46, 0xE8, 0x7B, 0x87, 0x74, 0xA2, 0x18,
		0x46, 0x31, 0xA9, 0x03, 0x14, 0x79, 0x82, 0x8E, 0xE9, 0x45, 0xA2, 0x49, 0x12, 0xA9, 0x23, 0x68,
		0x73, 0x89, 0xCF, 0x69, 0xA1, 0xB1, 0x61, 0x46, 0xBD, 0xC1, 0xBE, 0xBF, 0xD6, 0x01, 0x1B, 0xD8,
		0x81, 0xD4, 0xDC, 0x90, 0xFB, 0xFE, 0x4F, 0x52, 0x73, 0x66, 0xCB, 0x95, 0x70, 0xD7, 0xC5, 0x8E,
		0xBA, 0x1C, 0x7A, 0x33, 0x75, 0xA1, 0x62, 0x34, 0x46, 0xBB, 0x60, 0xB7, 0x80, 0x68, 0xFA, 0x13,
		0xA7, 0x7A, 0x8A, 0x37, 0x4B, 0x9E, 0xC6, 0xF4, 0x5D, 0x5F, 0x3A, 0x99, 0xF9, 0x9E, 0xC4, 0x3A,
		0xE9, 0x63, 0xA2, 0xBB, 0x88, 0x19, 0x28, 0xE0, 0xE7, 0x14, 0xC0, 0x42, 0x89, 0x02, 0x01, 0x11,
};

@implementation SKRSAEncryption

#pragma mark - Implementation

+ (NSData *)encryptData:(NSData *)data
{
	SecItemImportExportKeyParameters params;
	params.version			= SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	params.flags			= 0;
	params.passphrase		= NULL;
	params.alertTitle		= NULL;
	params.alertPrompt		= NULL;
	params.accessRef		= NULL;
	params.keyUsage			= NULL;
	params.keyAttributes	= NULL;
	SecTransformRef encrypt = NULL;
	CFErrorRef error		= NULL;
	
	// Create the key data
	NSData *keyData = [[NSData alloc] initWithBytes:&steamPublicKey2014 length:sizeof(steamPublicKey2014)];
	
	CFArrayRef tempArray;
	SecExternalItemType itemType	= kSecItemTypePublicKey;
	SecExternalFormat format		= kSecFormatUnknown;
	SecItemImport((CFDataRef)keyData, NULL, &format, &itemType, 0, &params, NULL, &tempArray);
	SecKeyRef publicKey		= (SecKeyRef)CFArrayGetValueAtIndex(tempArray, 0);
	
	encrypt = SecEncryptTransformCreate(publicKey, &error);
	
	// Set the attributes properly
	SecTransformSetAttribute(encrypt, kSecPaddingKey, kSecPaddingOAEPKey, &error);
	SecTransformSetAttribute(encrypt, kSecEncryptionMode, kSecModeNoneKey, &error);
	SecTransformSetAttribute(encrypt, kSecTransformInputAttributeName, (CFDataRef)data, &error);
	
	// Encrypt the data
	NSData *result = (NSData *)SecTransformExecute(encrypt, &error);
	if( error )
	{
		DLog(@"%@", (NSError *)error);
	}
	
	// Cleanup
	CFRelease(encrypt);
	[keyData release];
	
	return [result autorelease];
}

+ (NSData *)decryptData:(NSData *)data
{
	SecItemImportExportKeyParameters params;
	params.version			= SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	params.flags			= 0;
	params.passphrase		= NULL;
	params.alertTitle		= NULL;
	params.alertPrompt		= NULL;
	params.accessRef		= NULL;
	params.keyUsage			= NULL;
	params.keyAttributes	= NULL;
	
	NSString *filePath	= [[NSBundle mainBundle] pathForResource:@"private" ofType:@"pem"];
	NSData *keyData		= [[NSData alloc] initWithContentsOfFile:filePath];
	
	// Create the SecKeyRef from the private key data
	CFArrayRef			tempArray;
	SecExternalItemType itemType	= kSecItemTypePrivateKey;
	SecExternalFormat	format		= kSecFormatPEMSequence;
	SecItemImport((CFDataRef)keyData, NULL, &format, &itemType, 0, &params, NULL, &tempArray);
	SecKeyRef privateKey = (SecKeyRef)CFArrayGetValueAtIndex(tempArray, 0);
	[keyData release];
	
	// Create the transform
	SecTransformRef decrypt = NULL;
	CFErrorRef error		= NULL;
	decrypt = SecDecryptTransformCreate(privateKey, &error);
	if( error )
	{
		DLog(@"[Error %@", (NSError *)error);
		CFRelease(decrypt);
		return nil;
	}
	
	// Set its attributes and execute
	SecTransformSetAttribute(decrypt, kSecPaddingKey, kSecPaddingOAEPKey, &error);
	SecTransformSetAttribute(decrypt, kSecEncryptionMode, kSecModeNoneKey, &error);
	SecTransformSetAttribute(decrypt, kSecTransformInputAttributeName, (CFDataRef)data, &error);
	NSData *result = (NSData *)SecTransformExecute(decrypt, &error);
	if( error )
	{
		DLog(@"[Error] %@", (NSError *)error);
		CFRelease(decrypt);
		[result release];
		return nil;
	}
	
	// Cleanup
	CFRelease(decrypt);
	
	return [result autorelease];
}


/*- (void)generatePemFromKey
{
	NSData *key = [[NSData alloc] initWithBytes:&steamPublicKey2014 length:sizeof(steamPublicKey2014)];
	NSString *str = [key base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
	[key release];
	NSString *pemHeader = @"-----BEGIN RSA PUBLIC KEY-----\n";
	NSString *pemFooter = @"\n-----END RSA PUBLIC KEY-----";
	NSString *final = [NSString stringWithFormat:@"%@%@%@", pemHeader, str, pemFooter];
	[final writeToFile:@"/Users/jabwd/Desktop/steamInternal.pem" atomically:NO encoding:NSUTF8StringEncoding error:nil];
}*/

@end
