//
//  EXMemoryManager.m
//  Ice
//
//  Created by Antwan van Houdt on 14/11/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXMemoryManager.h"

@implementation EXMemoryManager

+ (instancetype)sharedManager
{
	static EXMemoryManager *sharedManager = nil;
	if( !sharedManager )
	{
		sharedManager = [[EXMemoryManager alloc] init];
	}
	return sharedManager;
}

- (id)init
{
	if( (self = [super init]) )
	{
		_list = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_list release]; _list = nil;
	[super dealloc];
}

#pragma mark - Implementation

- (void)putout
{
	NSLog(@"Memory List: %@", _list);
}

- (void)untrack
{
	NSArray *callStack = [NSThread callStackSymbols];
	NSString *source = [callStack objectAtIndex:1];
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-[]+?.,"];
	NSMutableArray *list = [NSMutableArray arrayWithArray:[source componentsSeparatedByCharactersInSet:set]];
	NSArray *list2 = [list[2] componentsSeparatedByString:@" "];
	
	NSString *class = list2[0];
	if( [class length] > 0 )
	{
		NSString *key = [NSString stringWithFormat:@"%@.release", class];
		if( _list[key] )
		{
			NSNumber *current = _list[key];
			UInt32 value = 0;
			if( [current unsignedIntValue] == 0 )
			{
				[_list removeObjectForKey:key];
				[self putout];
				return;
			}
			else if( current )
			{
				value = [current unsignedIntValue];
				--value;
			}
			_list[key] = [NSNumber numberWithUnsignedInt:value];
		}
		
		if( [callStack count] > 2 && [class isEqualToString:@"SKSession"] )
		{
			NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-[]+?.,"];
			NSMutableArray *list = [NSMutableArray arrayWithArray:[[callStack objectAtIndex:2] componentsSeparatedByCharactersInSet:set]];
			if( [list count] > 2 )
			{
				NSArray *list2 = [list[2] componentsSeparatedByString:@" "];
				NSString *callKey = [NSString stringWithFormat:@"%@.callers", class];
				if( _list[callKey] )
				{
					NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:_list[callKey]];
					for(NSUInteger i = 0;i<[arr count];i++)
					{
						NSString *str = arr[i];
						if( [str isEqualToString:list2[0]] )
						{
							[arr removeObjectAtIndex:i];
							break;
						}
					}
					_list[callKey] = arr;
					[arr release];
				}
			}
			else
			{
				NSLog(@"%@ Was ignored", list);
			}
		}
		
		[self putout];
	}
}

- (void)track
{
	NSArray *callStack = [NSThread callStackSymbols];
	NSString *source = [callStack objectAtIndex:1];
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-[]+?.,"];
	NSMutableArray *list = [NSMutableArray arrayWithArray:[source componentsSeparatedByCharactersInSet:set]];
	NSArray *list2 = [list[2] componentsSeparatedByString:@" "];
	
	NSString *class = list2[0];
	if( [class length] > 0 )
	{
		if( [class isEqualToString:@"SKSession"] )
		{
			//DLog(@"Source: %@", [NSThread callStackSymbols]);
		}
		NSString *key = [NSString stringWithFormat:@"%@.release", class];
		if( _list[key] )
		{
			NSNumber *current = _list[key];
			UInt32 value = 0;
			if( current )
			{
				value = [current unsignedIntValue];
				++value;
			}
			_list[key] = [NSNumber numberWithUnsignedInt:value];
		}
		else
		{
			// alloc was most likely called, autorelease can be tracked if untrack
			// is added to that method as well.
			_list[key] = [NSNumber numberWithUnsignedInt:2];
		}
		
		if( [callStack count] > 2 && [class isEqualToString:@"SKSession"] )
		{
			NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-[]+?.,"];
			NSMutableArray *list = [NSMutableArray arrayWithArray:[[callStack objectAtIndex:2] componentsSeparatedByCharactersInSet:set]];
			if( [list count] > 2 )
			{
				NSArray *list2 = [list[2] componentsSeparatedByString:@" "];
				NSString *callKey = [NSString stringWithFormat:@"%@.callers", class];
				NSMutableArray *arr = nil;
				if( _list[callKey] )
				{
					arr = [[NSMutableArray alloc] initWithArray:_list[callKey]];
				}
				else
				{
					arr = [[NSMutableArray alloc] init];
				}
				
				[arr addObject:list2[0]];
				_list[callKey] = arr;
				[arr release];
			}
			else
			{
				NSLog(@"%@ Was ignored", list);
			}
		}
		
		[self putout];
	}
}

@end
