//
//  EXImageView.h
//  Ice
//
//  Created by Antwan van Houdt on 21/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EXImageView : NSView
{
	NSImage *_avatarImage;
}
@property (retain) NSImage *avatarImage;

@end
