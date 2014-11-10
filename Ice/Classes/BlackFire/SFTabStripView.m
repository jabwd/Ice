//
//  SFTabStripView.m
//  BlackFire
//
//  Created by Antwan van Houdt on 11/6/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

#define TAB_OVERLAP		10.0f
#define TAB_HEIGHT		24.0f
#define TAB_WIDTH_MAX	2560.0f
#define TAB_WIDTH_MIN	80.0f

#import "SFTabStripView.h"
#import "SFTabView.h"

@implementation SFTabStripView


- (id)initWithFrame:(NSRect)frameRect
{
	if( (self = [super initWithFrame:frameRect]) )
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSWindowDidResignMainNotification object:self.window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSWindowDidBecomeMainNotification object:self.window];
		_tabs = [[NSMutableArray alloc] init];
		[self registerForDraggedTypes:@[BFPboardTabType]];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_tabs release];
	_tabs = nil;
	[super dealloc];
}

- (void)update {
	[self setNeedsDisplay:YES];
}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
	[super resizeWithOldSuperviewSize:oldSize];
	[self layoutTabs];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSImage *image;
	if( [[self window] isMainWindow] ) {
		image = [NSImage imageNamed:@"AW InactiveTabBG"];
	} else {
		image = [NSImage imageNamed:@"IW InactiveTabBG"];
	}
	
	[NSGraphicsContext saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, [self frame].origin.y)];
	
	[[NSColor colorWithPatternImage:image] set];
	NSRectFill([self bounds]);
	
	
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark - Laying out the tabs

- (void)selectTab:(SFTabView *)newSelected
{
	// make sure that all the tabviews think as themselves
	// as not selected
	for(SFTabView *tabView in _tabs)
	{
		if( tabView.selected ) {
			tabView.selected = NO;
		}
	}
	
	// make the newly selected the selected tabview
	newSelected.selected = YES;
	
	if( [_delegate respondsToSelector:@selector(didSelectNewTab:)] ) {
		[_delegate didSelectNewTab:newSelected];
	}
	
	// update the UI
	[self layoutTabs];
}

- (void)selectPreviousTab {
	NSInteger i, cnt = _tabs.count;
	for(i=0;i<cnt;i++) {
		SFTabView *tabView = _tabs[i];
		if( tabView.selected ) {
			i--;
			if( i < 0 ) {
				i = (cnt-1);
			}
			[self selectTab:_tabs[i]];
		}
	}
}

- (void)selectNextTab {
	NSInteger i, cnt = _tabs.count;
	for(i=0;i<cnt;i++) {
		SFTabView *tabView = _tabs[i];
		if( tabView.selected ) {
			i++;
			if( i >= cnt ) {
				i = 0;
			}
			[self selectTab:_tabs[i]];
		}
	}
}

- (void)layoutTabs
{
	CGFloat availableSpace = [self frame].size.width+(TAB_OVERLAP*([_tabs count]-1));
	CGFloat tabHeight = [self frame].size.height;
	CGFloat tabWidth = floor((CGFloat)availableSpace/((CGFloat)[_tabs count]));
	NSInteger i, cnt = [_tabs count];
	SFTabView *selected = nil;
	for(i=0;i<cnt;i++)
	{
		if( tabWidth > TAB_WIDTH_MAX ) {
			tabWidth = TAB_WIDTH_MAX;
		}
		NSRect viewFrame = NSMakeRect(floor(tabWidth*i-(i*TAB_OVERLAP)), 0, tabWidth, tabHeight);
		SFTabView *tab = _tabs[i];
		tab.tabDragAction = NO;
		if( tab.selected ) {
			selected = tab;
		}
		[tab setFrame:viewFrame];
		[tab updateTrackingAreas];
		
		// this makes sure that the ordering / drawing looks correct
		if( !selected ) {
			[tab orderOnTop];
			tab.tabRightSide = NO;
		} else if( tab != selected ) {
			tab.tabRightSide = YES;
		}
	}
	
	// for the tabs on the right side, lay them out
	// so that they look from highest to lowest from the
	// left to the right
	for(i=(cnt-1);i>=0;i--)
	{
		SFTabView *tab = _tabs[i];
		if( tab.selected ) {
			break; // done here.
		}
		
		[tab orderOnTop];
	}
	
	// the selected tab always is on top
	[selected orderOnTop];
}

#pragma mark - Managing tabs

- (void)tabViewWillClose:(SFTabView *)view
{
    if( [_delegate respondsToSelector:@selector(tabWillClose:)] ) {
        [_delegate tabWillClose:view];
	}
}

- (void)addTabView:(SFTabView *)tabView
{
	tabView.tabStrip = self;
	[self addSubview:tabView];
	[_tabs addObject:tabView];
	[self layoutTabs];
}

- (void)removeTabView:(SFTabView *)tabView
{
	tabView.tabStrip = nil;
	[tabView removeFromSuperview];
	
	NSUInteger i,cnt = [_tabs count];
	for(i=0;i<cnt;i++)
	{
		if( [_tabs[i] tag] == tabView.tag )
		{
			[_tabs removeObjectAtIndex:i];
			break;
		}
	}

	
	if( tabView.selected && [_tabs count] > 0  ) {
		[self selectTab:_tabs[0]];
	}
	
	[self layoutTabs];
}

- (SFTabView *)tabViewForTag:(NSUInteger)tag
{
	for(SFTabView *view in _tabs)
	{
		if( view.tag == tag )
			return view;
	}
	return nil;
}

- (void)tabViewStartedDragging:(SFTabView *)tabView {
	// update the current state of the tabs
	//CGFloat availableSpace	= [self frame].size.width+(TAB_OVERLAP*([_tabs count]-1));
	//CGFloat tabHeight		= [self frame].size.height;
	//CGFloat tabWidth		= floor((CGFloat)availableSpace/((CGFloat)[_tabs count]));
	
	NSInteger i, cnt = [_tabs count];
	NSRect ownFrame = tabView.frame;
	NSInteger tabIndex = 0;
	
	// find the tabIndex
	for(i=0;i<cnt;i++) {
		if( _tabs[i] == tabView ) {
			tabIndex = i;
			break;
		}
	}
	
	// figure out whether we have to move any tabs around
	for(i=0;i<cnt;i++)
	{
		SFTabView *tab = _tabs[i];
		if( tabView == tab ) {
			continue;
		}
		
		NSRect frame = [tab frame];
		
		// determine on which side ( relative to this tab ) the tab under this one is
		// then act accordingly.
		if( (frame.origin.x <= ownFrame.origin.x && (frame.origin.x+(frame.size.width/2)) >= ownFrame.origin.x) ||
			(frame.origin.x >= ownFrame.origin.x && (frame.origin.x) <= (ownFrame.origin.x+(ownFrame.size.width/2))) ) {
			// make sure that the order of the array of the tabs is still correct
			[_tabs exchangeObjectAtIndex:i withObjectAtIndex:tabIndex];
			tabIndex = i;
			
			// make sure that we reset all the tabs
			// so that rendering returns to 'normal'
			for(SFTabView *view in _tabs) {
				view.tabDragAction = NO;
			}
			
			/*tab.tabDragAction = YES;*/
			
			// the tabs on the left and right of the currently selected tabs are always
			// in the 'dragaction' which means they render both the left and right caps
			if( (tabIndex-1) >= 0 ) {
				SFTabView *leftTab = _tabs[tabIndex-1];
				leftTab.tabDragAction = YES;
			}
			if( (tabIndex+1) < cnt ) {
				SFTabView *rightTab = _tabs[tabIndex+1];
				rightTab.tabDragAction = YES;
			}
			
			if( tab.tabRightSide ) {
				tab.tabRightSide = NO;
			} else {
				tab.tabRightSide = YES;
			}
			
			// Finally: actually move the view
			//[tab moveToFrame:tabView.originalRect];
			[tab setFrame:tabView.originalRect];
			tabView.originalRect = frame;
			break;
		}
	}
}

- (void)aTabIsDragging
{
	// make sure that every tab goes in 'tabdrag' mode
	for(SFTabView *view in _tabs) {
		view.tabDragAction = YES;
	}
}

- (void)tabDoneDragging
{	
	[self layoutTabs];
}

#pragma mark - Dragging and dropping

- (void)createNewTabStripForTabView:(SFTabView *)tabview location:(NSPoint)location {
	if( [_delegate respondsToSelector:@selector(createNewWindowWithTabstripForView:)] ) {
		SFTabStripView *view = [_delegate createNewWindowWithTabstripForView:tabview];
		
		// make sure that the dropped off location is the new location of the window
		NSRect viewFrame = view.frame;
		[[view window] setFrameOrigin:NSMakePoint(location.x, location.y-viewFrame.origin.y)];
		// remove the tab from its old tab strip
		[self removeTabView:tabview];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if( [[sender draggingSource] isKindOfClass:[SFTabView class]] )
	{
		return NSDragOperationLink;
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
	SFTabView *tabView = [sender draggingSource];
	if( [tabView isKindOfClass:[SFTabView class]] ) {
		return YES;
	}
	return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	SFTabView *tabView = [sender draggingSource];
	if( [tabView isKindOfClass:[SFTabView class]] ) {
		//SFTabStripView *old = tabView.tabStrip;
		DLog(@"Dragging is not supported right now");
		//[[ADAppDelegate sharedDelegate] moveTabView:tabView toNewStrip:self];
		return YES;
	}
	return NO;
}

@end
