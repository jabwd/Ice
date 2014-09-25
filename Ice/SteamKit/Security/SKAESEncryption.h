//
//  SKAESEncryption.h
//  Ice
//
//  Created by Antwan van Houdt on 24/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKAESEncryption : NSObject

/**
 * Generates random data of a given length
 * useful for generating session keys etc. for encryption
 *
 * @param NSUInteger length the length of the data
 *
 * @return NSData			the generated data
 */
+ (NSData *)generateRandomData:(NSUInteger)length;

/**
 * Encrypts the given data with the given key and initialisation vector
 * using AES128 encryption and PKCS7 padding mode
 *
 * @param NSData data   data to encrypt ( will be padded )
 * @param NSData key	the key to use
 * @param NSData iv		the initialisation vector for the encryption
 *
 * @return NSData		encrypted data
 */
+ (NSData *)encryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv;

/**
 * Decrypts the given data using the given key and initialisation vector
 * using the AES128 algorithm
 *
 * @param NSData data	data to decrypt
 * @param NSData key	the key that was used for the encryption of the data
 * @param NSData iv		the initialisation vector used for the encryption
 *
 * @return NSData		the decrypted data
 */
+ (NSData *)decryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv;

@end
