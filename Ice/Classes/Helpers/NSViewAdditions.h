//
//  NSViewAdditions.h
//  BlackFire
//
//  Created by Antwan van Houdt on 11/7/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (Additions)

/*
 * This method makes sure that the view is on top of every other subview
 * in its container ( superview )
 */
- (void)orderOnTop;

- (void)orderOnTopOfView:(NSView *)otherView;

@end
