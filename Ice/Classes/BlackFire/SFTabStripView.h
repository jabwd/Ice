//
//  SFTabStripView.h
//  BlackFire
//
//  Created by Antwan van Houdt on 11/6/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SFTabView.h"
#import "NSViewAdditions.h"

@protocol TabStripDelegate <NSObject>
/**
 * Called when a new tab becomes the selected
 * tab view. Connect your mode switching or whatever
 * you do to this action
 */
- (void)didSelectNewTab:(SFTabView *)tabView;

/**
 * Called when a user closes a tab
 */
- (void)tabWillClose:(SFTabView *)tabView;

/**
 * This method is for the drag and drop of tabs
 * Will be called to notify that the delegate should create
 * a new tabstrip
 */
- (SFTabStripView *)createNewWindowWithTabstripForView:(SFTabView *)view;
@end

@interface SFTabStripView : NSView <SFTabViewDelegate>

@property (readonly) NSMutableArray *tabs;
@property (assign) id <TabStripDelegate> delegate;

//---------------------------------------------------------------------------------
// Laying out the tabs

- (void)selectTab:(SFTabView *)newSelected;
- (void)selectNextTab;
- (void)selectPreviousTab;


- (SFTabView *)tabViewForTag:(NSUInteger)tag;
- (void)addTabView:(SFTabView *)tabView;
- (void)removeTabView:(SFTabView *)tabView;

- (void)layoutTabs;

/**
 * Called by SFTabView when a drag action occurs
 * Called everytime the frame of the SFTabView is updated
 */
- (void)tabViewStartedDragging:(SFTabView *)tabView;

- (void)tabDoneDragging;

/**
 * Called by SFTabView when the tabView wants a new window and
 * tab strip to live in
 */
- (void)createNewTabStripForTabView:(SFTabView *)tabview location:(NSPoint)location;
@end
