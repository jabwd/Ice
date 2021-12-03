//
//  SKProtobufHeader.m
//  Ice
//
//  Created by Antwan van Houdt on 09/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufHeader.h"
#import "SKPacket.h"
#import "SKProtobufScanner.h"

@implementation SKProtobufHeader

- (id)initWithPacket:(SKPacket *)packet
{
	if( (self = [super init]) )
	{
		_steamID	= [packet.scanner.header[@"1"] unsignedIntegerValue];
		_sessionID	= [packet.scanner.header[@"2"] unsignedIntValue];
		
		_sourceID = [packet.scanner.header[@"10"] unsignedIntegerValue];
		_targetID = [packet.scanner.header[@"11"] unsignedIntegerValue];
	}
	return self;
}

@end
