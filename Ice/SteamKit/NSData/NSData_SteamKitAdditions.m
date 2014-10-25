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

#import "NSData_SteamKitAdditions.h"

@implementation NSData (SteamKitAdditions)

+ (NSData *)dataFromByteString:(NSString *)byteString
{
	// Cleanup the string to actual bytes we can use
	// Just in case we get the string from different kind of sources
	NSString *dataString = [byteString stringByReplacingOccurrencesOfString:@" " withString:@""];
	dataString = [dataString stringByReplacingOccurrencesOfString:@"0x" withString:@""];
	
	NSInteger bytes = (NSInteger)([dataString length]/2);
	NSMutableData *buffer = [[NSMutableData alloc] init];
	for(NSUInteger i = 0;i<bytes;i++)
	{
		NSString *byte = [dataString substringWithRange:NSMakeRange(i*2, 2)];
		char actualByte = (char)strtol([byte UTF8String], NULL, 16);
		[buffer appendBytes:&actualByte length:1];
	}
	return [buffer autorelease];
}

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

#pragma mark - SteamKit extras

- (UInt32)getUInt32
{
	UInt32 value = 0;
	[self getBytes:&value length:sizeof(UInt32)];
	return value;
}

- (UInt16)getUInt16
{
	UInt16 value = 0;
	[self getBytes:&value length:sizeof(UInt16)];
	return value;
}

- (UInt8)getUInt8
{
	return [self getByte];
}

- (UInt8)getByte
{
	UInt8 value = 0;
	[self getBytes:&value length:1];
	return value;
}

@end
