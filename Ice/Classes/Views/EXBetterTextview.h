//
//  EXBetterTextview.h
//  Ice
//
//  Created by Antwan van Houdt on 22/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EXBetterTextview : NSTextView
{
	BOOL _needsScroll;
}

- (void)setNeedsScrolledDisplay;

@end
