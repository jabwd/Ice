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

const NSString *EXChatFontName	= @"Helvetica Neue";
const CGFloat EXChatFontSize	= 12.0f;

@implementation EXChatWindowController

- (id)initWithFriend:(SKFriend *)remoteFriend
{
	if( (self = [super initWithWindowNibName:@"EXChatWindowController" owner:self]) )
	{
		_remoteFriend			= [remoteFriend retain];
		_remoteFriend.delegate	= self;
		
		[self.window makeKeyAndOrderFront:nil];
		self.window.styleMask |= NSFullSizeContentViewWindowMask;
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
	
	[self.window setDelegate:self];
	[self.window setTitle:[NSString stringWithFormat:@"Chat - %@", [_remoteFriend displayName]]];
	[_messageField becomeFirstResponder];
}

- (IBAction)send:(id)sender
{
	NSString *message = [[_messageField stringValue] retain];
	[_messageField setStringValue:@""];
	[_remoteFriend sendMessage:message ofType:SKChatEntryTypeMessage];
	
	[self addSelfMessage:message date:[NSDate date]];
	[message release];
}

#pragma mark - Chat delegate

- (void)friendDidReceiveMessage:(NSString *)message date:(NSDate *)date type:(SKChatEntryType)entryType
{
	if( entryType == SKChatEntryTypeMessage && [message length] > 0 )
	{
		[self addFriendMessage:message date:date];
		
		NSBeep();
	}
	else if( entryType == SKChatEntryTypeTyping )
	{
		NSLog(@"Received an isTyping notification");
	}
}

- (void)addFriendMessage:(NSString *)message date:(NSDate *)date
{
	NSString *dateString	= [NSDateFormatter localizedStringFromDate:date
														  dateStyle:NSDateFormatterNoStyle
														  timeStyle:NSDateFormatterShortStyle];
	NSString *name			= [_remoteFriend displayName];
	
	
	NSString *finalMessage = [NSString stringWithFormat:
							  @"%@ - %@: %@\n",
							  dateString,
							  name,
							  message];
	
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:finalMessage attributes:nil];
	
	[str addAttribute:NSFontAttributeName value:[NSFont fontWithName:(NSString *)EXChatFontName size:EXChatFontSize] range:NSMakeRange(0, [finalMessage length])];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [finalMessage length])];
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
	NSString *name			= [_remoteFriend.session.currentUser displayName];
	
	
	NSString *finalMessage = [NSString stringWithFormat:
							  @"%@ - %@: %@\n",
							  dateString,
							  name,
							  message];
	
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:finalMessage attributes:nil];
	
	[str addAttribute:NSFontAttributeName value:[NSFont fontWithName:(NSString *)EXChatFontName size:EXChatFontSize] range:NSMakeRange(0, [finalMessage length])];
	[str addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [finalMessage length])];
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
