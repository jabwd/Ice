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

- (void)removeBytes:(NSUInteger)length
{
	[self replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
}

@end
