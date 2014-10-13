//
//  SKRSAEncryption.m
//  Ice
//
//  Created by Antwan van Houdt on 25/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKRSAEncryption.h"
#import "NSData_XfireAdditions.h"
#import <Security/Security.h>

/*
 30 81 9D 30 0D 06 09 2A 86 48 86 F7 0D 01 01 01
 05 00 03 81 8B 00 30 81 87 02 81 81 00
 
 {DF EC 1A
 D6 2C 10 66 2C 17 35 3A 14 B0 7C 59 11 7F 9D D3
 D8 2B 7A E3 E0 15 CD 19 1E 46 E8 7B 87 74 A2 18
 46 31 A9 03 14 79 82 8E E9 45 A2 49 12 A9 23 68
 73 89 CF 69 A1 B1 61 46 BD C1 BE BF D6 01 1B D8
 81 D4 DC 90 FB FE 4F 52 73 66 CB 95 70 D7 C5 8E
 BA 1C 7A 33 75 A1 62 34 46 BB 60 B7 80 68 FA 13
 A7 7A 8A 37 4B 9E C6 F4 5D 5F 3A 99 F9 9E C4 3A
 E9 63 A2 BB 88 19 28 E0 E7 14 C0 42 89}
 
 02 01 11
 */
/* 
 Beta:
 30 81 9D 30 0D 06 09 2A 86 48 86 F7 0D 01 01 01
 05 00 03 81 8B 00 30 81 87 02 81 81 00
 
 {AE D1 4B
 C0 A3 36 8B A0 39 0B 43 DC ED 6A C8 F2 A3 E4 7E
 09 8C 55 2E E7 E9 3C BB E5 5E 0F 18 74 54 8F F3
 BD 56 69 5B 13 09 AF C8 BE B3 A1 48 69 E9 83 49
 65 8D D2 93 21 2F B9 1E FA 74 3B 55 22 79 BF 85
 18 CB 6D 52 44 4E 05 92 89 6A A8 99 ED 44 AE E2
 66 46 42 0C FB 6E 4C 30 C6 6C 5C 16 FF BA 9C B9
 78 3F 17 4B CB C9 01 5D 3E 37 70 EC 67 5A 33 48
 F7 46 CE 58 AA EC D9 FF 4A 78 6C 83 4B}
 
 02 01 11
 */

/*static const unsigned char steamPublicKey[] = {
	0xDF, 0xEC, 0x1A, 0xD6, 0x2C, 0x10, 0x66, 0x2C,
	0x17, 0x35, 0x3A, 0x14, 0xB0, 0x7C, 0x59, 0x11,
	0x7F, 0x9D, 0xD3, 0xD8, 0x2B, 0x7A, 0xE3, 0xE0,
	0x15, 0xCD, 0x19, 0x1E, 0x46, 0xE8, 0x7B, 0x87,
	0x74, 0xA2, 0x18, 0x46, 0x31, 0xA9, 0x03, 0x14,
	0x79, 0x82, 0x8E, 0xE9, 0x45, 0xA2, 0x49, 0x12,
	0xA9, 0x23, 0x68, 0x73, 0x89, 0xCF, 0x69, 0xA1,
	0xB1, 0x61, 0x46, 0xBD, 0xC1, 0xBE, 0xBF, 0xD6,
	0x01, 0x1B, 0xD8, 0x81, 0xD4, 0xDC, 0x90, 0xFB,
	0xFE, 0x4F, 0x52, 0x73, 0x66, 0xCB, 0x95, 0x70,
	0xD7, 0xC5, 0x8E, 0xBA, 0x1C, 0x7A, 0x33, 0x75,
	0xA1, 0x62, 0x34, 0x46, 0xBB, 0x60, 0xB7, 0x80,
	0x68, 0xFA, 0x13, 0xA7, 0x7A, 0x8A, 0x37, 0x4B,
	0x9E, 0xC6, 0xF4, 0x5D, 0x5F, 0x3A, 0x99, 0xF9,
	0x9E, 0xC4, 0x3A, 0xE9, 0x63, 0xA2, 0xBB, 0x88,
	0x19, 0x28, 0xE0, 0xE7, 0x14, 0xC0, 0x42, 0x89
};

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
};*/

@implementation SKRSAEncryption

- (id)init
{
	if( (self = [super init]) )
	{
		
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark - Implementation

- (NSData *)encryptData:(NSData *)data
{
	SecItemImportExportKeyParameters params;
	params.version			= SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	params.flags			= 0; // See SecKeyImportExportFlags for details.
	params.passphrase		= NULL;
	params.alertTitle		= NULL;
	params.alertPrompt		= NULL;
	params.accessRef		= NULL;
	params.keyUsage			= NULL;
	params.keyAttributes	= NULL;
	
	NSString *filePath	= [[NSBundle mainBundle] pathForResource:@"public" ofType:@"pem"];
	NSData *keyData		= [[NSData alloc] initWithContentsOfFile:filePath];
	
	CFArrayRef tempArray;
	SecExternalItemType itemType	= kSecItemTypePublicKey;
	SecExternalFormat format		= kSecFormatPEMSequence;
	SecItemImport((CFDataRef)keyData, NULL, &format, &itemType, 0, &params, NULL, &tempArray);
	SecKeyRef publicKey		= (SecKeyRef)CFArrayGetValueAtIndex(tempArray, 0);
	[keyData release];
	SecTransformRef encrypt = NULL;
	CFErrorRef error = NULL;
	encrypt = SecEncryptTransformCreate(publicKey, &error);
	SecTransformSetAttribute(encrypt, kSecTransformInputAttributeName, (CFDataRef)data, &error);
	NSData *result = (NSData *)SecTransformExecute(encrypt, &error);
	CFRelease(encrypt);
	return [result autorelease];
}

- (NSData *)decryptData:(NSData *)data
{
	SecItemImportExportKeyParameters params;
	params.version			= SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	params.flags			= 0; // See SecKeyImportExportFlags for details.
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
	NSData *key = [[NSData alloc] initWithBytes:NULL length:0];
	NSString *str = [key base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
	[key release];
	NSString *pemHeader = @"-----BEGIN PUBLIC KEY-----\n";
	NSString *pemFooter = @"\n-----END PUBLIC KEY-----";
	NSString *final = [NSString stringWithFormat:@"%@%@%@", pemHeader, str, pemFooter];
	[final writeToFile:@"/Users/jabwd/Desktop/steamPublic.pem" atomically:NO encoding:NSUTF8StringEncoding error:nil];
}*/

@end
