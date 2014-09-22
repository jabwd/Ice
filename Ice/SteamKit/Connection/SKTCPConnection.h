//
//  SKTCPConnection.h
//  Ice
//
//  Created by Antwan van Houdt on 18/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKConnection.h"
#import "GCDAsyncSocket.h"

@interface SKTCPConnection : SKConnection <GCDAsyncSocketDelegate>
{
	GCDAsyncSocket *_socket;
}

- (id)initWithAddress:(NSString *)address;

@end
