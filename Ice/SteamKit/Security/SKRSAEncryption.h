//
//  SKRSAEncryption.h
//  Ice
//
//  Created by Antwan van Houdt on 25/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKRSAEncryption : NSObject

/**
 * Encrypts the given data using the built in public key
 *
 * @param NSData	the data to encrypt using the public key
 *					cannot be nil
 *
 * @return NSData	the encrypted data
 */
- (NSData *)encryptData:(NSData *)data;

/**
 * Decrypts the given data with the given private key
 *
 * @param NSData	the RSA encrypted data
 *
 * @return NSData	the decrypted data or nil
 */
- (NSData *)decryptData:(NSData *)data;
@end
