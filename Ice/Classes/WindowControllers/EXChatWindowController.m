//
//  EXChatWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXChatWindowController.h"
#import "SKSession.h"
#import <AutoHyperlinks/AutoHyperlinks.h>
#import "BFNotificationCenter.h"
#import "SFTabStripView.h"
#import "SFTabView.h"
#import "EXBetterTextview.h"
#import "XNResizingMessageView.h"

NSString *EXChatFontName		= @"Helvetica Neue";
const CGFloat EXChatFontSize	= 14.0f;

@implementation EXChatWindowController

- (id)initWithFriend:(SKFriend *)remoteFriend
{
	if( (self = [super initWithWindowNibName:@"EXChatWindowController" owner:self]) )
	{
		_remoteFriend			= [remoteFriend retain];
		_remoteFriend.delegate	= self;
		
		_missedMessagesCount	= 0;
		
		//self.window.titleVisibility = NSWindowTitleHidden;
		self.window.delegate		= self;
		[self.window makeKeyAndOrderFront:nil];
	}
	return self;
}

- (void)dealloc
{
	_remoteFriend.delegate = nil;
	[_remoteFriend release];
	_remoteFriend = nil;
	[super dealloc];
}

- (BOOL)windowShouldClose:(id)sender
{
	_remoteFriend.delegate = nil;
	if( [_delegate respondsToSelector:@selector(shouldCloseController:)] )
	{
		[_delegate shouldCloseController:self];
	}
	return YES;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.window.title			= [NSString stringWithFormat:@"Chat - %@", _remoteFriend.displayNameString];
	
	//[_messageView becomeFirstResponder];
	[_messageView setEnabled:YES];
	[_messageView setMessageDelegate:self];
	
	SFTabView *tabView = [[SFTabView alloc] init];
	tabView.title = self.window.title;
	[_stripView addTabView:tabView];
	//[_stripView setDelegate:self];
	[tabView release];
	
	[self.window setContentBorderThickness:35.0 forEdge:NSMinYEdge];
	[self.window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	
	[self.window makeFirstResponder:_messageView];
	
	// Set default values
	[_textView setFont:[NSFont fontWithName:EXChatFontName size:EXChatFontSize]];
	[_textView setTextColor:[NSColor blackColor]];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[[BFNotificationCenter defaultNotificationCenter] deleteBadgeCount:_missedMessagesCount];
	_missedMessagesCount = 0;
}

- (void)goOffline
{
	[_messageView setEnabled:NO];
}

#pragma mark - Message view delegate

- (void)sendMessage:(NSString *)message
{
	_previousStamp = 0;
	
	[_remoteFriend sendMessage:message ofType:SKChatEntryTypeMessage];
	[self processMessage:message
					from:_remoteFriend.session.currentUser
					date:[NSDate date]
				  ofType:EXChatMessageTypeSelf];
	
	[[BFNotificationCenter defaultNotificationCenter] playSendSound];
}

- (void)controlTextChanged
{
	NSUInteger now = [[NSDate date] timeIntervalSince1970];
	if( (now-_previousStamp) > 15 )
	{
		[_remoteFriend sendMessage:nil ofType:SKChatEntryTypeTyping];
		_previousStamp = now;
	}
}

- (void)resizeMessageView:(id)messageView
{
	NSWindow *window = self.window;
	NSScrollView *messageScrollView = (NSScrollView *)[[_messageView superview] superview];
	NSScrollView *scrollView = (NSScrollView *)[[_textView superview] superview];
	
	// change the size of the message scroll view
	NSSize size = [(XNResizingMessageView *)messageView desiredSize];
	NSRect frame = [messageScrollView frame];
	CGFloat heightAddition = size.height - frame.size.height;
	frame.size.height += heightAddition;
	[messageScrollView setFrame:frame];
	
	// change the window frame
	NSRect windowFrame = [window frame];
	windowFrame.size.height += heightAddition;
	windowFrame.origin.y -= heightAddition;
	CGFloat height = [window contentBorderThicknessForEdge:NSMinYEdge];
	height += heightAddition;
	[window setContentBorderThickness:height forEdge:NSMinYEdge];
	NSRect mainView = [scrollView frame];
	mainView.origin.y += heightAddition;
	mainView.size.height -= heightAddition;
	if( heightAddition < 0 )
	{
		[scrollView setFrame:mainView];
	}
	else
		[scrollView setFrame:mainView];
	[window setFrame:windowFrame display:YES animate:NO];
}

#pragma mark - Chat delegate

- (void)friendStatusDidChange
{
	NSString *message = nil;
	
	message = [[NSString alloc] initWithFormat:@"%@ is now %@",
			   [_remoteFriend displayNameString],
			   [_remoteFriend statusDisplayString]];
	
	[self processMessage:message from:nil date:[NSDate date] ofType:EXChatMessageTypeNotification];
	[message release];
}

- (void)friendDidReceiveMessage:(NSString *)message date:(NSDate *)date type:(SKChatEntryType)entryType
{
	if( entryType == SKChatEntryTypeMessage && [message length] > 0 )
	{
		[self processMessage:message
						from:_remoteFriend
						date:date
					  ofType:EXChatMessageTypeFriend];
		
		[[BFNotificationCenter defaultNotificationCenter] playReceivedSound];
		if( ![self.window isKeyWindow] )
		{
			[[BFNotificationCenter defaultNotificationCenter] postNotificationWithTitle:[_remoteFriend displayNameString]
																				   body:[NSString stringWithFormat:@"%@", message]];
			[[BFNotificationCenter defaultNotificationCenter] addBadgeCount:1];
			
			_missedMessagesCount++;
			
			[NSApp requestUserAttention:NSInformationalRequest];
		}
		
		// Remove the isTyping
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(removeIsTyping)
												   object:nil];
		[self removeIsTyping];
	}
	else if( entryType == SKChatEntryTypeTyping )
	{
		[_isTypingView setImage:[NSImage imageNamed:@"pencil"]];
		[self performSelector:@selector(removeIsTyping)
				   withObject:nil
				   afterDelay:20.0f];
	}
	else if( entryType == SKChatEntryTypeInviteGame )
	{
		[self processMessage:@"Invited you to a game"
						from:nil
						date:[NSDate date]
					  ofType:EXChatMessageTypeNotification];
	}
	else if( entryType == SKChatEntryTypeLeftConversation )
	{
		[self processMessage:@"Your 'friend' closed the chat window"
						from:nil
						date:[NSDate date]
					  ofType:EXChatMessageTypeNotification];
	}
	else
	{
		DLog(@"Unhandled chat notificaiton %u", entryType);
	}
}

- (void)removeIsTyping
{
	[_isTypingView setImage:nil];
}

- (void)processMessage:(NSString *)message from:(SKFriend *)sender date:(NSDate *)date ofType:(EXChatMessageType)type
{
	NSString *dateString	= [NSDateFormatter localizedStringFromDate:date
														  dateStyle:NSDateFormatterNoStyle
														  timeStyle:NSDateFormatterShortStyle];
	NSString *name			= [sender displayNameString];
	NSString *finalMessage	= [[NSString alloc] initWithFormat:
							   @"%@ - %@: %@\n",
							   dateString,
							   name,
							   message];
	NSColor	*nameColor		= nil;
	NSFont *font			= [NSFont fontWithName:EXChatFontName size:EXChatFontSize];
	
	switch(type)
	{
		case EXChatMessageTypeSelf:
			nameColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.8f alpha:1.0f];
			break;
			
		case EXChatMessageTypeFriend:
			nameColor = [NSColor colorWithCalibratedRed:0.8f green:0.0f blue:0.0f alpha:1.0f];
			break;
			
		case EXChatMessageTypeNotification:
			nameColor = [NSColor colorWithCalibratedRed:0.3f green:0.3f blue:0.3f alpha:1.0f];
			[finalMessage release];
			finalMessage = [[NSString alloc] initWithFormat:@"<%@ - %@>\n", dateString, message];
			break;
	}
	
	// Generate a colored version of the finalMessage string
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:finalMessage attributes:nil];
	
	// Set the default attributes for the entire string, just to be sure.
	[str addAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [NSColor blackColor]} range:NSMakeRange(0, [finalMessage length])];
	
	if( type != EXChatMessageTypeNotification )
	{
		[str addAttribute:NSForegroundColorAttributeName
					value:nameColor
					range:NSMakeRange([dateString length]+3, [name length]+1)];
		[str addAttribute:NSForegroundColorAttributeName
					value:[NSColor colorWithCalibratedWhite:0.3f alpha:1.0f]
					range:NSMakeRange(0, [dateString length])];
	}
	else
	{
		[str addAttribute:NSForegroundColorAttributeName
					value:nameColor
					range:NSMakeRange(0, [finalMessage length])];
	}
	
	[self appendToTextView:str];
	[str release];
	[finalMessage release];
}

- (void)scrollToBottom;
{
	NSPoint newScrollOrigin;
	NSScrollView *scrollview = (NSScrollView *)[[_textView superview] superview];
	// assume that the scrollview is an existing variable
	if ([[scrollview documentView] isFlipped]) {
		newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollview documentView] frame])
									-NSHeight([[scrollview contentView] bounds]));
	} else {
		newScrollOrigin=NSMakePoint(0.0,0.0);
	}
	[[scrollview documentView] scrollPoint:newScrollOrigin];
 
}

- (void)appendToTextView:(NSAttributedString *)str
{
	AHHyperlinkScanner *scanner = [[AHHyperlinkScanner alloc] initWithAttributedString:str usingStrictChecking:NO];
	[[_textView textStorage] appendAttributedString:[scanner linkifiedString]];
	//[_textView setNeedsDisplay:YES];
	[(EXBetterTextview *)_textView setNeedsScrolledDisplay];
	[scanner release];
}

@end
