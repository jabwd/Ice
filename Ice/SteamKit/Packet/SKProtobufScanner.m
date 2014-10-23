//
//  SKProtobufScanner.m
//  Ice
//
//  Created by Antwan van Houdt on 23/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "SKProtobufScanner.h"

NSUInteger const ProtoMask = 0x80000000;

@implementation SKProtobufScanner

- (id)initWithData:(NSData *)packetData
{
	if( (self = [super init]) )
	{
		_data	= [[NSMutableData alloc] initWithData:packetData];
		_map	= nil;
		
		if( [_data length] > 0 )
		{
			[self performScan];
		}
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	_data = nil;
	[_map release];
	_map = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (void)performScan
{
	
}

- (void)loadMap:(NSString *)mapName
{
	NSString *path		= [[NSBundle mainBundle] pathForResource:mapName ofType:@"plist" inDirectory:@"Protobuf"];
	NSDictionary *map	= [[NSDictionary alloc] initWithContentsOfFile:path];
	if( map )
	{
		[_map release];
		_map = [map retain];
	}
	[map release];
}

- (WireType)typeAtFieldNumber:(NSUInteger)fieldNumber
{
	return WireTypeVarint;
}

- (id)valueForKey:(NSString *)key
{
	if( !_map )
	{
		NSLog(@"Error: cannot get valueForKey with protoscanner without loading a protobuf map");
		return nil;
	}
	NSString *fieldNumber		= _map[key];
	NSUInteger actualNumber		= [fieldNumber integerValue];
	if( actualNumber > 0 )
	{
		return [self valueForFieldNumber:actualNumber];
	}
	return nil;
}

- (id)valueForFieldNumber:(NSUInteger)fieldNumber
{
	if( fieldNumber >= [_values count] )
	{
		return nil;
	}
	return _values[fieldNumber];
}

@end
