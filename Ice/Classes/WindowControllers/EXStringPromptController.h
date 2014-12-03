//
//  EXStringPromptController.h
//  Ice
//
//  Created by Antwan van Houdt on 03/12/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EXStringPromptController : NSWindowController

- (id)initWithNibName:(NSString *)name completionHandler:(void (^)(void))completionHandler;

@end
