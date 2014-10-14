/*******************************************************************
	FILE:		NSMutableData_XfireAdditions.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Adds items to NSMutableData that are useful for implementing
		the Xfire protocol.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 10 13  Created.
*******************************************************************/

#import "NSMutableData_XfireAdditions.h"

@implementation NSMutableData (XfireAdditions)

- (void)appendByte:(unsigned char)b
{
	unsigned char dat[1];
	dat[0] = b;
	
	[self appendBytes:dat length:1];
}

// remove bytes in a given range, causing bytes after the specified range
// to be moved up right after the bytes at the beginning of the initial range
//
// 4 CASES:
//          +----------------------------+ (Entire data)
//     1:   +----------------------------+ Covers entire length        Trunc only, no copy
//     2:   +-------------+                Covers start but not end    Copy and trunc
//     3:           +------------+         Covers some middle range    Copy and trunc
//     4:                    +-----------+ Covers end but not start    Trunc only, no copy
- (void)removeBytesInRange:(NSRange)delRange
{
	NSLog(@"*** Deprecated method called, removeBytesInRange (NSMutableData additions)");
	[self replaceBytesInRange:delRange withBytes:NULL length:0];
	return;
	
	NSRange ourRange = NSMakeRange(0, [self length]);
	char* mutBytes = [self mutableBytes];
	NSRange endRange;
	
	// Degenerate case
	if( delRange.length == 0 )
		return;
	
	// Truncate delRange, if necessary
	if( (delRange.location + delRange.length) > ourRange.length )
	{
		delRange.length = ourRange.length - delRange.location;
	}
	
	// CASE 1: Range covers the entire buffer
	// CASE 2: Range covers start but not end
	if( delRange.location == ourRange.location )
	{
		// CASE 1: Range covers the entire buffer
		if( delRange.length >= ourRange.length )
		{
			[self setLength:0];
			return;
		}
		
		// CASE 2: Range covers start but not end
		endRange.location = (delRange.location+delRange.length);
		endRange.length = (ourRange.length - delRange.length);
		memcpy( (mutBytes+delRange.location), // dst
			(mutBytes+endRange.location), // src
			endRange.length ); // count
		[self setLength:endRange.length];
		return;
	}
	
	// CASE 4: Range does not include start, covers to end
	if( (delRange.location+delRange.length) >= (ourRange.location+ourRange.length) )
	{
		// cover end but not start, so just truncate
		[self setLength:delRange.location];
		return;
	}
	
	// CASE 3: Range covers some middle region
	// copy bytes from end range up to where delRange is, then truncate length
	endRange.location = delRange.location + delRange.length;
	endRange.length = ourRange.length - delRange.location - delRange.length;
	
	memcpy( (mutBytes+delRange.location), // dst
		(mutBytes+endRange.location), // src
		endRange.length ); // count
	[self setLength:(delRange.location + endRange.length)];
}

@end
