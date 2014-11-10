//
//  EXChatWindowController.m
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXChatWindowController.h"
#import "SKSession.h"

@implementation EXChatWindowController

- (id)initWithFriend:(SKFriend *)remoteFriend
{
	if( (self = [super initWithWindowNibName:@"EXChatWindowController" owner:self]) )
	{
		_remoteFriend = [remoteFriend retain];
		_remoteFriend.delegate = self;
	}
	return self;
}

- (void)dealloc
{
	[_remoteFriend release];
	_remoteFriend = nil;
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.window setTitle:[NSString stringWithFormat:@"Chat - %@", [_remoteFriend displayName]]];
	[_messageField becomeFirstResponder];
}

- (IBAction)send:(id)sender
{
	NSString *message = [[_messageField stringValue] retain];
	[_messageField setStringValue:@""];
	[_remoteFriend sendMessage:message ofType:SKChatEntryTypeMessage];
	
	SKFriend *currentUser = _remoteFriend.session.currentUser;
	[self appendToTextView:[NSString stringWithFormat:@"[%@]%@: %@\n",
							[NSDateFormatter localizedStringFromDate:[NSDate date]
														   dateStyle:NSDateFormatterNoStyle
														   timeStyle:NSDateFormatterShortStyle],
							[currentUser displayName],
							message]];
	[message release];
}

#pragma mark - Chat delegate

- (void)friendDidReceiveMessage:(NSString *)message date:(NSDate *)date type:(SKChatEntryType)entryType
{
	if( entryType == SKChatEntryTypeMessage && [message length] > 0 )
	{
		[self appendToTextView:[NSString stringWithFormat:@"[%@]%@: %@\n",
								[NSDateFormatter localizedStringFromDate:date
															   dateStyle:NSDateFormatterNoStyle
															   timeStyle:NSDateFormatterShortStyle],
								[_remoteFriend displayName],
								message]];
		
		NSBeep();
	}
	else if( entryType == SKChatEntryTypeTyping )
	{
		NSLog(@"Received an isTyping notification");
	}
}

- (void)appendToTextView:(NSString *)str
{
	NSAttributedString *attr = [[NSAttributedString alloc] initWithString:str];
	[[_textView textStorage] appendAttributedString:attr];
	[_textView scrollRangeToVisible:NSMakeRange([[_textView string] length], 0)];
	[attr release];
	[_textView setNeedsDisplay:YES];
}

@end
