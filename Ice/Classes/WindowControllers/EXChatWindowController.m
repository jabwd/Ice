//
//  EXChatWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXChatWindowController.h"
#import "SKSession.h"
#import "AHHyperlinkScanner.h"
#import "BFNotificationCenter.h"
#import "SFTabStripView.h"
#import "SFTabView.h"

const NSString *EXChatFontName	= @"Helvetica Neue";
const CGFloat EXChatFontSize	= 12.0f;

@implementation EXChatWindowController

- (id)initWithFriend:(SKFriend *)remoteFriend
{
	if( (self = [super initWithWindowNibName:@"EXChatWindowController" owner:self]) )
	{
		_remoteFriend			= [remoteFriend retain];
		_remoteFriend.delegate	= self;
		
		_missedMessagesCount	= 0;
		
		self.window.titleVisibility = NSWindowTitleHidden;
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
	
	[_messageField becomeFirstResponder];
	
	SFTabView *tabView = [[SFTabView alloc] init];
	tabView.title = self.window.title;
	[_stripView addTabView:tabView];
	[tabView release];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[[BFNotificationCenter defaultNotificationCenter] deleteBadgeCount:_missedMessagesCount];
	_missedMessagesCount = 0;
}

- (IBAction)send:(id)sender
{
	NSString *message = [[_messageField stringValue] retain];
	[_messageField setStringValue:@""];
	[_remoteFriend sendMessage:message ofType:SKChatEntryTypeMessage];
	
	[self addSelfMessage:message date:[NSDate date]];
	[message release];
	
	[[BFNotificationCenter defaultNotificationCenter] playSendSound];
}

#pragma mark - Chat delegate

- (void)friendDidReceiveMessage:(NSString *)message date:(NSDate *)date type:(SKChatEntryType)entryType
{
	if( entryType == SKChatEntryTypeMessage && [message length] > 0 )
	{
		[self addFriendMessage:message date:date];
		
		[[BFNotificationCenter defaultNotificationCenter] playReceivedSound];
		if( ![self.window isKeyWindow] )
		{
			[[BFNotificationCenter defaultNotificationCenter] postNotificationWithTitle:[_remoteFriend displayNameString] body:[NSString stringWithFormat:@"%@", message]];
			_missedMessagesCount++;
			[[BFNotificationCenter defaultNotificationCenter] addBadgeCount:1];
			[NSApp requestUserAttention:NSInformationalRequest];
			[NSObject cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(removeIsTyping)
													   object:nil];
		}
	}
	else if( entryType == SKChatEntryTypeTyping )
	{
		[_isTypingView setImage:[NSImage imageNamed:@"pencil"]];
		[self performSelector:@selector(removeIsTyping)
				   withObject:nil
				   afterDelay:20.0f];
	}
}

- (void)removeIsTyping
{
	[_isTypingView setImage:nil];
}

- (void)addFriendMessage:(NSString *)message date:(NSDate *)date
{
	NSString *dateString	= [NSDateFormatter localizedStringFromDate:date
														  dateStyle:NSDateFormatterNoStyle
														  timeStyle:NSDateFormatterShortStyle];
	NSString *name			= [_remoteFriend displayNameString];
	
	
	NSString *finalMessage = [NSString stringWithFormat:
							  @"%@ - %@: %@\n",
							  dateString,
							  name,
							  message];
	
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:finalMessage attributes:nil];
	
	[str addAttribute:NSFontAttributeName value:[NSFont fontWithName:(NSString *)EXChatFontName size:EXChatFontSize] range:NSMakeRange(0, [finalMessage length])];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [finalMessage length])];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange([dateString length]+3, [name length]+1)];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedWhite:0.3f alpha:1.0f] range:NSMakeRange(0, [dateString length])];
	
	[self appendToTextView:str];
	
	[str release];
}

- (void)addSelfMessage:(NSString *)message date:(NSDate *)date
{
	NSString *dateString	= [NSDateFormatter localizedStringFromDate:date
														  dateStyle:NSDateFormatterNoStyle
														  timeStyle:NSDateFormatterShortStyle];
	NSString *name			= [_remoteFriend.session.currentUser displayNameString];
	
	
	NSString *finalMessage = [NSString stringWithFormat:
							  @"%@ - %@: %@\n",
							  dateString,
							  name,
							  message];
	
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:finalMessage attributes:nil];
	
	[str addAttribute:NSFontAttributeName value:[NSFont fontWithName:(NSString *)EXChatFontName size:EXChatFontSize] range:NSMakeRange(0, [finalMessage length])];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [finalMessage length])];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange([dateString length]+3, [name length]+1)];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedWhite:0.3f alpha:1.0f] range:NSMakeRange(0, [dateString length])];
	
	[self appendToTextView:str];
	
	[str release];
}

- (void)appendToTextView:(NSAttributedString *)str
{
	AHHyperlinkScanner *scanner = [[AHHyperlinkScanner alloc] initWithAttributedString:str usingStrictChecking:NO];
	
	[[_textView textStorage] appendAttributedString:[scanner linkifiedString]];
	//[_textView scrollRangeToVisible:NSMakeRange([[_textView string] length], 0)];
	[[_textView animator] scrollRangeToVisible:NSMakeRange([[_textView string] length], 0)];
	[_textView setNeedsDisplay:YES];
	[scanner release];
}

@end
