//
//  EXFriendsListRowView.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EXImageView;

@interface EXFriendsListRowView : NSTableCellView

@property (assign) IBOutlet NSTextField *statusField;
@property (assign) IBOutlet EXImageView *avatarView;
@property (assign) IBOutlet NSImageView *statusImageView;

- (void)setShowsStatusField:(BOOL)showsStatus;

- (void)setAvatarImage:(NSImage *)avatarImage;

@end
