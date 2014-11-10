//
//  EXFriendsListController.h
//  Ice
//
//  Created by Antwan van Houdt on 10/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SKSession;

@interface EXFriendsListController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	SKSession *_session;
}

- (id)initWithSession:(SKSession *)session;

@end
