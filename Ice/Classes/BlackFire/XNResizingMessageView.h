//
//  XNResizingMessageView.h
//  TextFieldTest
//
//  Created by Antwan van Houdt on 2/15/12.
//  Copyright (c) 2012 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol BFChatMessageViewDelegate
- (void)controlTextChanged;
- (void)sendMessage:(NSString *)message;
- (void)resizeMessageView:(id)messageView;
@end

@interface XNResizingMessageView : NSTextView

@property (unsafe_unretained) id <BFChatMessageViewDelegate> messageDelegate;
@property (assign) NSInteger maxLength;
@property (nonatomic, assign) BOOL enabled;


//------------------------------------------------------------------------------------
// Auto resizing

- (NSSize)desiredSize;

//------------------------------------------------------------------------------------
// Misc

- (void)previousMessage;
- (void)nextMessage;
- (void)addMessage:(NSString *)message;
- (void)becomeKey;
- (void)setEnabled:(BOOL)enabled;

@end
