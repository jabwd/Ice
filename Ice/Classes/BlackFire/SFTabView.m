//
//  SFTabView.m
//  BlackFire
//
//  Created by Antwan van Houdt on 11/7/11.
//  Copyright (c) 2011 Antwan van Houdt. All rights reserved.
//

// TODO: Add Snow leopard support

#import "SFTabView.h"
#import "SFTabStripView.h"

#define CLOSE_ANIMATION NO

NSString *BFPboardTabType = @"BFPboardTabType";

@implementation SFTabView
{	
	NSRect _originalRect;
	NSRect _latestRect;
	NSPoint _originalPoint;
	
	BOOL _mouseInside;
	BOOL _mouseInsideClose;
	BOOL _mouseDownInsideClose;
}

- (id)initWithFrame:(NSRect)frame
{
    if( (self = [super initWithFrame:frame]) )
	{
		_title = nil;
		
		_tabDragAction = NO;
		_mouseInside = NO;
		
		
		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSMakeRect(8, 0, frame.size.width-8, frame.size.height) options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
		[self addTrackingArea:trackingArea];
		[trackingArea release];
	}
    return self;
}

- (void)dealloc
{
	_tabStrip = nil;
	[_title release];
	_title = nil;
	[_image release];
	_image = nil;
	
	[super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)drawRect:(NSRect)useless
{
	NSRect dirtyRect = [self bounds];
	
	// the window key determines whether it is the key window or not
	NSColor *backgroundColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0f];
	
	if( ![[self window] isMainWindow] ) {
		backgroundColor = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0f];
	}
	[backgroundColor set];
	NSRectFill(dirtyRect);
	
	NSImage *closeImage = [NSImage imageNamed:@"NSStopProgressTemplate"];
	
	// improves the way the tabs are drawn on the screen
	if( _tabDragAction || self.selected )
	{
	}
	else
	{
		[[NSColor colorWithCalibratedWhite:0.66 alpha:1.0f] set];
		if( _tabRightSide )
		{
			NSRectFill(NSMakeRect(dirtyRect.size.width-1, 0, 1, 24));
		}
		else
		{
			NSRectFill(NSMakeRect(0, 0, 1, 24));
		}
	}
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
	[style setAlignment:NSCenterTextAlignment];
	
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.41]];
	
	// determine the appropriate text color for the control
	NSColor *textColor = nil;
	if( [[self window] isMainWindow] )
	{
		textColor = [NSColor colorWithCalibratedWhite:0.2f alpha:1.0f];
	}
	else
	{
		textColor = [NSColor disabledControlTextColor];
	}
	
	NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:11.0f];
	font = [[NSFontManager sharedFontManager] convertWeight:YES ofFont:font];
	
	NSDictionary *attributes = @{
		NSParagraphStyleAttributeName: style,
		NSShadowAttributeName: shadow,
		NSForegroundColorAttributeName: textColor,
		NSFontAttributeName: font
	};
	[shadow release];
	
	if( ! _title )
	{
		_title = @"";
	}
	
	NSAttributedString *titleAttrStr = [[NSAttributedString alloc] initWithString:_title attributes:attributes];
	NSSize stringSize = [titleAttrStr size];
	
	// here we create the vertically centered 'box' for the string to be drawn in
	// with the Y coordinate we subtract 1 point in order to make it feel more centered
	//NSRect stringRect = NSMakeRect(dirtyRect.origin.x+26, (dirtyRect.size.height/2)-(stringSize.height/2)-1.0f, dirtyRect.size.width-52, stringSize.height);
	
	NSRect stringRect;
	stringRect.size.height	= stringSize.height;
	stringRect.size.width	= dirtyRect.size.width-50;
	stringRect.origin.x		= dirtyRect.origin.x+25;
	stringRect.origin.y		= (dirtyRect.size.height/2)-(stringSize.height/2)+2;
	
	[titleAttrStr drawInRect:stringRect];
	[titleAttrStr release];
	
	// draw the close button on top of everything
	if( _mouseInside )
	{
		if( _mouseInsideClose )
		{
			NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5, 3, 18, 18)
																 xRadius:2.0f
																 yRadius:2.0f];
			[[NSColor colorWithCalibratedWhite:0.6f alpha:1.0f] set];
			[path fill];
		}
		
		[closeImage drawInRect:NSMakeRect(10, 8, 8, 8) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	}
	else if( _image )
	{
		//[_image drawInRect:NSMakeRect(10, 4, 14, 13) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	}
	
	
	// draw the missed messages counter if applicable
	if( _missedMessages > 0 )
	{
		NSDictionary *newAttr = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor whiteColor],NSForegroundColorAttributeName,style,NSParagraphStyleAttributeName, nil];
		NSAttributedString *countString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu",_missedMessages] attributes:newAttr];
		[newAttr release];
		
		// draw some sort of bezel around it
		NSRect stringRect = NSMakeRect(dirtyRect.size.width-20-[countString size].width, 4, [countString size].width, 13);
		NSBezierPath *bezelPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(stringRect.origin.x, stringRect.origin.y, stringRect.size.width+10, stringRect.size.height+2) xRadius:8.0f yRadius:7.0f];
		if( [[self window] isMainWindow] )
			[[NSColor darkGrayColor] set];
		else
			[[NSColor colorWithCalibratedWhite:0.6f alpha:1.0f] set];
		[bezelPath fill];
		
		[countString drawInRect:NSMakeRect(dirtyRect.size.width-15-[countString size].width, 6, [countString size].width, 13)];
		[countString release];
	}
	[style release];
}


- (void)mouseEntered:(NSEvent *)theEvent
{
	_mouseInside = YES;
	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {	
	_mouseInside = NO;
	[self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];

	NSArray *trackingAreas = [self trackingAreas];
	NSUInteger i, cnt = [trackingAreas count];
	for(i=0;i<cnt;i++)
	{
		[self removeTrackingArea:trackingAreas[i]];
	}
	NSRect frame = [self frame];
	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSMakeRect(8, 0, frame.size.width-8, frame.size.height) options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved) owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
	[trackingArea release];
}

/**
 * For the rollover effect of the close button
 */
- (void)mouseMoved:(NSEvent *)theEvent {
	// get the mouse location in this view
	NSPoint mousePoint = [NSEvent mouseLocation];
	NSRect mouseRect = [[self window] convertRectFromScreen:NSMakeRect(mousePoint.x, mousePoint.y, 1, 1)];
	NSPoint actual = [self convertPoint:mouseRect.origin
							   fromView:[[[self window] contentView] superview]];
	
	//NSPoint actual = [self convertPoint:[[self window] convertScreenToBase:mousePoint] fromView:[[[self window] contentView] superview]];
	
	// determine whether it is inside the rect of the close box
	if( actual.x > 10 && actual.x < 22 && actual.y > 3 && actual.y < 19 ) {
		_mouseInsideClose = YES;
	} else {
		_mouseInsideClose = NO;
	}
	[self setNeedsDisplay:YES];
}

/**
 * This will allow us to keep dragging a tab even though we're not inside the tabview anymore
 */
- (void)mouseDown:(NSEvent *)theEvent {
	[self mouseDown_proxy:theEvent];
	_keepOn = YES;
    //BOOL isInside	= YES;
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//	NSPoint mouseDownLocation = mouseLoc;
	
    while( _keepOn )
	{
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
					NSLeftMouseDraggedMask];
		
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSRect bounds = [self bounds];
		//isInside = [self mouse:mouseLoc inRect:bounds];
		
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
				[self mouseDragged_proxy:theEvent];
				
				NSRect dragStartRect = NSMakeRect(bounds.origin.x-20.0f, bounds.origin.y-20.0f, bounds.size.width+40.0f, bounds.size.height+50.0f);
				if( ![self mouse:mouseLoc inRect:dragStartRect] /*&& _tabStrip.tabs.count > 1*/ )
				{
					/*NSSize dragOffset = NSMakeSize(0.0, 0.0);
					NSPasteboard *pboard;
					NSImage *displayImage = [self displayImage];
					pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
					[pboard declareTypes:[NSArray arrayWithObject:BFPboardTabType]  owner:self];
					[pboard setData:[[NSString stringWithFormat:@"tabview_%@",self] dataUsingEncoding:NSUTF8StringEncoding ] forType:BFPboardTabType];
					
					NSPoint imageLocation = NSMakePoint(mouseLoc.x-mouseDownLocation.x, mouseLoc.y-mouseDownLocation.y);
					
					
					//[self dragImage:displayImage at:imageLocation offset:dragOffset
					//		  event:theEvent pasteboard:pboard source:self slideBack:NO];*/
				}
				
				break;
            case NSLeftMouseUp:
				[self mouseUp_proxy:theEvent];
				
				_mouseInside		= NO;
				_mouseInsideClose	= NO;
				_keepOn				= NO;
				break;
            default:
				/* Ignore any other kind of event. */
				break;
        }
    };
	
    return;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
	NSPoint newScreenPoint = [[self window] convertScreenToBase:screenPoint];
	NSPoint mouseLocation = [self convertPoint:newScreenPoint fromView:nil];
	NSRect bounds = [self bounds];
	NSRect dragStartRect = NSMakeRect(bounds.origin.x-20.0f, bounds.origin.y-20.0f, bounds.size.width+40.0f, bounds.size.height+50.0f);
	if( ![self mouse:mouseLocation inRect:dragStartRect] && operation == NSDragOperationNone ) {
		// should create a new window with a new tab strip
		[self.tabStrip createNewTabStripForTabView:self location:screenPoint];
	}
	[self mouseUp_proxy:nil];
	_mouseInside		= NO;
	_mouseInsideClose	= NO;
	_keepOn				= NO;
}



- (NSImage *)displayImage
{
	NSBitmapImageRep *bitmap;
	[self lockFocus];
	bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[self bounds]];
	[self unlockFocus];
	NSImage *img = [[NSImage alloc] initWithCGImage:[bitmap CGImage] size:[bitmap size]];
	[bitmap release];
	return [img autorelease];
}

- (void)mouseDown_proxy:(NSEvent *)theEvent
{
	_dragging = NO;
	
	_originalPoint	= [NSEvent mouseLocation];
	_originalRect	= [self frame];
	
	NSPoint new = [[self window] convertRectFromScreen:NSMakeRect(_originalPoint.x, _originalPoint.y, 1, 1)].origin;
	NSPoint actual = [self convertPoint:new
							   fromView:[[[self window] contentView] superview]];
	
	if( actual.x > 10 && actual.x < 22 && actual.y > 3 && actual.y < 19 )
	{
		_mouseDownInsideClose = YES;
		_mouseInsideClose = YES;
		[self setNeedsDisplay:YES];
		return;
	}
	else
	{
		if( !_selected )
		{
			SFTabStripView *strip = (SFTabStripView *)[self superview];
			[strip selectTab:self];
		}
		_mouseInsideClose = NO;
		_mouseDownInsideClose = NO;
	}
}

- (void)mouseDragged_proxy:(NSEvent *)theEvent
{
	// for some reason mouseDragged is called when vigorously dragging with the window around your screen,
	// in order not to make the tab feel retarded: do this.
	if( ! _mouseInside || [_tabStrip.tabs count] < 2 ) {
		[super mouseDragged:theEvent];
		return;
	}

	NSPoint newPoint	= [NSEvent mouseLocation];
	CGFloat deltaX		= _originalPoint.x - newPoint.x;
	
	// if we are not dragging start dragging
	if( !_dragging ) {
		// makes sure that we have a 'magnetic' feeling
		// by only starting the drag once we have more than 10
		// moved delta points. This feels to be a bit like what safari
		// is using, but of course I can not say this for sure
		if( deltaX < 10.0f && deltaX > -10.0f ) {
			return;
		} else {
			_dragging		= YES;
			_originalRect	= [self frame];
			
			// the tabs on the left and right of the currently selected tabs are always
			// in the 'dragaction' which means they render both the left and right caps
			NSArray *tabs = [_tabStrip tabs];
			NSInteger i, cnt = [tabs count];
			for(i = 0;i<cnt;i++) {
				if( _tabStrip.tabs[i] == self ) {
					if( (i-1) >= 0 ) {
						SFTabView *leftTab = tabs[i-1];
						leftTab.tabDragAction = YES;
					}
					if( (i+1) < cnt ) {
						SFTabView *rightTab = tabs[i+1];
						rightTab.tabDragAction = YES;
					}
					break;
				}
			}
		}
	}
	
	// move us according to the mouse delta
	NSRect ownFrame = [self frame];
	ownFrame.origin.x -= deltaX;
	
	// make sure that we can't go off the tabstrip
	if( ownFrame.origin.x < 0 ) {
		ownFrame.origin.x = 0;
	} else if( (ownFrame.origin.x+ownFrame.size.width) > _tabStrip.frame.size.width ) {
		ownFrame.origin.x = _tabStrip.frame.size.width-ownFrame.size.width;
	}
	
	// get the new 'origin' and update our frame
	_originalPoint = [NSEvent mouseLocation];
	[self setFrame:ownFrame];
	
	
	[_tabStrip tabViewStartedDragging:self];
	
	/*NSUInteger i, cnt = [_tabStrip.tabs count];
	for(i=0;i<cnt;i++)
	{
		SFTabView *tabView = (_tabStrip.tabs)[i];
		if( tabView == self )
			continue;
		
		NSRect frame = [tabView frame];
		if( tabView.animating )
		{
			frame = tabView.proposedLocation;
		}
		
		// determine on which side ( relative to this tab ) the tab under this one is
		// then act accordingly.
		if( frame.origin.x <= ownFrame.origin.x )
		{
			if( (frame.origin.x+(frame.size.width/2)) >= ownFrame.origin.x )
			{
				//[tabView setFrame:_originalRect];
				[tabView moveToFrame:_originalRect];
				_originalRect = frame;
				NSUInteger idx = [_tabStrip.tabs indexOfObject:self];
				[_tabStrip.tabs exchangeObjectAtIndex:i withObjectAtIndex:idx];
				return;
			}
		}
		else if( frame.origin.x >= ownFrame.origin.x )
		{
			if( (frame.origin.x) <= (ownFrame.origin.x+(ownFrame.size.width/2)) )
			{
				//[tabView setFrame:_originalRect];
				[tabView moveToFrame:_originalRect];
				_originalRect = frame;
				NSUInteger idx = [_tabStrip.tabs indexOfObject:self];
				[_tabStrip.tabs exchangeObjectAtIndex:i withObjectAtIndex:idx];
				return;
			}
		}
	}*/
}

- (void)mouseUp_proxy:(NSEvent *)theEvent
{
	// determine whether we are still inside the current box
	// for closing the tab, if so perform close the tab
	if( _mouseDownInsideClose )
	{
		
		NSPoint new		= [[self window] convertRectFromScreen:NSMakeRect(_originalPoint.x, _originalPoint.y, 1, 1)].origin;
		NSPoint actual	= [self convertPoint:new fromView:[[[self window] contentView] superview]];
		if( actual.x > 10 && actual.x < 22 && actual.y > 3 && actual.y < 19 )
		{
			/*[NSAnimationContext beginGrouping];
			[[NSAnimationContext currentContext] setDuration:0.125f];
			[[NSAnimationContext currentContext] setCompletionHandler:^{
				if( [_tabStrip respondsToSelector:@selector(tabViewWillClose:)] )
					[_tabStrip tabViewWillClose:self];
			}];
			NSRect frame = self.frame;
			[[self animator] setFrame:NSMakeRect(frame.origin.x, frame.origin.y, 2, frame.size.height)];
			[NSAnimationContext endGrouping];*/ // enable this later on
			if( [_tabStrip respondsToSelector:@selector(tabViewWillClose:)] ) {
                [_tabStrip tabViewWillClose:self];
			}
			
		}
		_mouseInsideClose = NO;
		_mouseDownInsideClose = NO;
	}
	
	
	if( _dragging ) {
		_dragging = NO;
		[_tabStrip tabDoneDragging];
	}
	
	if( !_selected ) {
		return;
	}
	
	
	[self setFrame:_originalRect];
	[_tabStrip layoutTabs];
}

- (void)moveToFrame:(NSRect)newFrame
{
	/*if( _animating )
	{
		_latestRect = newFrame;
		// will be handled later on.
		return;
	}*/
	/*[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:.125f];
	_animating = YES;
	_latestRect = NSZeroRect;
	_proposedLocation = newFrame;
	[[self animator] setFrame:newFrame];
	[self performSelector:@selector(animationCleanup) withObject:nil afterDelay:.125f];
	[NSAnimationContext endGrouping];*/
	[self setFrame:newFrame];

}

@end
