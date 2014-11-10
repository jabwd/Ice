//
//  SFTabView.h
//  BlackFire
//
//  Created by Antwan van Houdt on 11/7/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SFTabStripView, SFTabView;

@protocol SFTabViewDelegate <NSObject>
- (void)tabViewWillClose:(SFTabView *)tabView;
@end

extern NSString *BFPboardTabType;

@interface SFTabView : NSView
{
	BOOL _keepOn;
}

@property (assign) SFTabStripView *tabStrip;

@property (assign) NSUInteger missedMessages;
@property (assign) NSRect originalRect;

@property (assign) BOOL selected;
@property (assign) BOOL tabDragAction;
@property (assign) BOOL tabRightSide;
@property (assign) BOOL dragging;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSImage *image;

/*
 * This animates the tabview to the new location
 * and when animating stops the current animation and 
 * starts moving again 
 */
- (void)moveToFrame:(NSRect)newFrame;

@end
