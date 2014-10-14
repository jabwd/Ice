/*******************************************************************
	FILE:		NSData_XfireAdditions.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Adds items to NSData that are useful for implementing the
		Xfire protocol.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 10 14  Created.
*******************************************************************/

#import "NSData_XfireAdditions.h"
//#include <openssl/sha.h>

@implementation NSData (XfireAdditions)

- (unsigned int)crc32 {
	unsigned int crc32 = 0;
	
	if( [self length] ) 
	{
		unsigned int p_len = (unsigned int)[self length];
		const void *p_data = [self bytes];
		
		crc32 = 0xffffffff;
		
		unsigned int i;
		for(i = 0; i < p_len; i++) 
		{
			crc32 = (crc32 >> 8) ^ crc32table[((unsigned char *)p_data)[i] ^ (crc32 & 0x000000ff)];
		}
		return ~crc32;
	}
	return crc32;
}

/*- (NSData *)sha1Hash
{
	SHA_CTX			ctx;
	unsigned char	hash[SHA_DIGEST_LENGTH];
	
	SHA1_Init(&ctx);
	SHA1_Update(&ctx,[self bytes],[self length]);
	SHA1_Final(hash,&ctx);
	
	return [NSData dataWithBytes:hash length:SHA_DIGEST_LENGTH];
}

- (NSString *)sha1HexHash {
	unsigned char digest[SHA_DIGEST_LENGTH];
	char hashString[(2 * SHA_DIGEST_LENGTH) + 1];
	
	SHA1([self bytes], [self length], digest);
	
	NSInteger currentIndex = 0;
	
	for (currentIndex = 0; currentIndex < SHA_DIGEST_LENGTH; currentIndex++) {
		
		sprintf(hashString+currentIndex*2, "%02x", digest[currentIndex]);
	}
	hashString[currentIndex * 2] = 0;
	
	return [NSString stringWithUTF8String:(const char *)hashString];
}*/

// prints raw hex + ascii
- (NSString *)enhancedDescription
{
	NSMutableString *str   = [NSMutableString string]; // full string result
	NSMutableString *hrStr = [NSMutableString string]; // "human readable" string
	
	int i, len;
	const unsigned char *b;
	len = (unsigned int)[self length];
	b = [self bytes];
	
	if( len == 0 )
	{
		return @"<empty>";
	}
	
	[str appendString:@"\n   "];
	
	int linelen = 16;
	for( i = 0; i < len; i++ )
	{
		[str appendFormat:@" %02x", b[i]];
		if( isprint(b[i]) )
		{
			[hrStr appendFormat:@"%c", b[i]];
		}
		else
		{
			[hrStr appendString:@"."];
		}
		
		if( (i % linelen) == (linelen-1) ) // new line every linelen bytes
		{
			[str appendFormat:@"    %@\n", hrStr];
			hrStr = [NSMutableString string];
			
			if( i < (len-1) )
			{
				[str appendString:@"   "];
			}
		}
	}
	
	// make sure to print out the remaining hrStr part, aligned of course
	if( (len % linelen) != 0 )
	{
		int bytesRemain = linelen-(len%linelen); // un-printed bytes
		for( i = 0; i < bytesRemain; i++ )
		{
			[str appendString:@"   "];
		}
		[str appendFormat:@"    %@\n", hrStr];
	}
	
	return str;
}

- (unsigned char)byteAtIndex:(unsigned int)index
{
	const unsigned char *b = [self bytes];
	return b[index];
}

// tests for all zeros
- (BOOL)isClear
{
	unsigned short i,cnt = [self length];
	const unsigned char *b = [self bytes];
	for( i = 0; i < cnt; i++ )
	{
		if( b[i] != 0 )
			return NO;
	}
	return YES;
}

/*+ (NSData *)newUUID
{
	CFUUIDRef uuid;
	NSData    *dat = nil;
	
	uuid = CFUUIDCreate(nil);
	if( uuid != nil )
	{
		CFUUIDBytes bytes;
		
		bytes = CFUUIDGetUUIDBytes(uuid);
		dat = [NSData dataWithBytes:&bytes length:16];
		
		CFRelease(uuid);
	}
	return dat;
}*/

- (NSData *)dataByTruncatingZeroedData {
	NSMutableData *data = [NSMutableData data];
	NSUInteger length = [self length];
	NSUInteger i = 0;
	for (i = 0; i < length; i++) {
		unsigned char byte = 0;
		[self getBytes:&byte range:NSMakeRange(i, sizeof(unsigned char))];
		if (byte) {
			[data appendBytes:&byte length:sizeof(unsigned char)];
		} else {
			break;
		}
	}
	return [NSData dataWithData:data];
}

#if 0
+ (id)stringWithNewUUID
{
	CFUUIDRef		uuid;
	CFStringRef		cfstr;
	NSString		*nstr;
	
	uuid = CFUUIDCreate(nil);
	cfstr = CFUUIDCreateString(nil, uuid);
	nstr = (NSString *)cfstr;
	CFRelease(uuid);
	
	return nstr;
}
#endif

- (NSString *)stringRepresentation {
	const char *bytes = [self bytes];
	NSUInteger length = [self length];
	NSUInteger index;
	
	NSMutableString *stringRepresentation = [NSMutableString string];
	
	for (index = 0; index < length; index++) {
		[stringRepresentation appendFormat:@"%02x", (unsigned char)bytes[index]];
	}
	return [[stringRepresentation copy] autorelease];
}

@end
