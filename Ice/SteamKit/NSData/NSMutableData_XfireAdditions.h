/*******************************************************************
	FILE:		NSMutableData_XfireAdditions.h
	
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

#import <Cocoa/Cocoa.h>

@interface NSMutableData (XfireAdditions)

- (void)appendByte:(unsigned char)b;

- (void)removeBytes:(NSUInteger)length;

@end
