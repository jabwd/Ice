//
//  SKOneTimePassword.h
//  Ice
//
//  Created by Antwan van Houdt on 29/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKOneTimePassword : NSObject
{
	SInt32 _type;
	UInt32 _value;
	
	NSString *_identifier;
}
@property (retain) NSString *identifier;

@end
