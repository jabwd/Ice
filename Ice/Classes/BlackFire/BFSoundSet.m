//
//  BFSoundSet.m
//  BlackFire
//
//  Created by Antwan van Houdt on 12/29/11.
//  Copyright (c) 2011 Exurion. All rights reserved.
//

#import "BFSoundSet.h"

@implementation BFSoundSet

- (id)initWithContentsOfFile:(NSString *)path
{
	if( (self = [super init]) )
	{
		_path = [path retain];
		BOOL isDir = NO;
		if( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir )
		{
			// determine what kind of bundle we are handling here.
			if( [path hasSuffix:@"AdiumSoundset"] || [path hasSuffix:@"AdiumSoundSet"] )
			{
				[self decodeAdiumSoundSetAtPath:path];
			}
			else if( [path hasSuffix:@".BlackFireSnd"] || [path hasSuffix:@".BlackFireSoundset"] || [path hasSuffix:@".BlackFireSoundSet"] )
			{
				[self decodeBlackFireSoundSetAtPath:path];
			}
			else
			{
				NSLog(@"*** %@ Cannot decode soundset at path %@",NSStringFromClass([self class]),path);
			}
		}
		else
		{
			NSLog(@"*** %@ Cannot load soundset at path %@",NSStringFromClass([self class]),path);
		}
	}
	return self;
}

- (void)dealloc
{
	[_path release];
	_path = nil;
	[_receiveSoundPath release];
	_receiveSoundPath = nil;
	[_sendSoundPath release];
	_sendSoundPath = nil;
	[_onlineSoundPath release];
	_onlineSoundPath = nil;
	[_offlineSoundPath release];
	_offlineSoundPath = nil;
	[_connectedSoundPath release];
	_connectedSoundPath = nil;
	[_name release];
	_name = nil;
	[super dealloc];
}


#pragma mark - Decoding bundles

- (void)decodeAdiumSoundSetAtPath:(NSString *)path
{
	NSString *informationPath = [[[NSString alloc] initWithFormat:@"%@/Sounds.plist",path] autorelease];
	NSDictionary *information = [[[NSDictionary alloc] initWithContentsOfFile:informationPath] autorelease];
	
	if( ! information )
	{
		//NSLog(@"Notice: no info property list found in the adium soundset, probably some retard who thinks using a plain text file is handier");
		// scan the plain text file, *sigh*
		// oh, another bonus from these retards, the file can have a random name :D
		NSError *error = nil;
		NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
		if( ! error )
		{
			NSString *filePath = nil;
			for(NSString *fileName in directoryContents)
			{
				if( [fileName rangeOfString:@".txt"].length > 0 )
				{
					filePath = [NSString stringWithFormat:@"%@/%@",path,fileName];
					break;
				}
			}
			
			if( ! filePath )
			{
				return;
			}
			else
			{
				NSString *contents = [[[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error] autorelease];
				if( error )
				{
					NSLog(@"*** Unable to decode adium soundset");
					return;
				}
				else
				{
					// scan the file for the information we need
					NSArray *components = [contents componentsSeparatedByString:@"\n"];
					BOOL useful = NO;
					information = [(NSDictionary *)[[NSMutableDictionary alloc] init] autorelease];
					if( [components count] > 0 )
					{
						NSString *name = components[0];
						((NSMutableDictionary *)information)[@"Info"] = name;
					}
					else
					{
						return;
					}
					for(NSString *line in components)
					{
						if( ! useful )
						{
							if( [line length] > 8 )
							{
								if( [line rangeOfString:@"SoundSet:"].length == 9 )
								{
									useful = YES;
								}
							}
						}
						else
						{
							NSString *key	= nil;
							NSString *value = nil;
							NSArray *comp = [line componentsSeparatedByString:@"\""];
							if( [comp count] > 2 )
							{
								key		= comp[1];
								value	= comp[2];
								
								// finish the value
								NSRange valueRange = [value rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
								valueRange.length = [value length] - valueRange.location;
								value = [value substringWithRange:valueRange];
							}
							if( key && value )
							{
								((NSMutableDictionary *)information)[key] = value;
							}
						}
					}
				}
			}
		}
		else
		{
			return;
		}
	}
	
	if( information )
	{
		NSString *soundsetFile = [_path lastPathComponent];
		NSArray *comp = [soundsetFile componentsSeparatedByString:@"."];
		if( [comp count] > 0 )
		{
			_name = [comp[0] retain];
		}
		
		if( ! _name )
			_name = [@"Untitled" retain];
		
		
		NSDictionary *sounds = information[@"Sounds"];
		if( ! sounds )
			sounds = information;
		
		[_receiveSoundPath release];
		_receiveSoundPath = nil;
		if( [sounds[@"Message Received"] length] > 0 )
			_receiveSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,sounds[@"Message Received"]];
		
		[_sendSoundPath release];
		_sendSoundPath = nil;
		if( [sounds[@"Message Sent"] length] > 0 )
			_sendSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,sounds[@"Message Sent"]];
		
		[_onlineSoundPath release];
		_onlineSoundPath = nil;
		if( [sounds[@"Contact Signed On"] length] > 0 )
			_onlineSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,sounds[@"Contact Signed On"]];
		
		[_offlineSoundPath release];
		_offlineSoundPath = nil;
		if( [sounds[@"Contact Signed Off"] length] > 0 )
			_offlineSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,sounds[@"Contact Signed Off"]];
		
		[_connectedSoundPath release];
		_connectedSoundPath = nil;
		if( [sounds[@"Connected"] length] > 0 )
			_connectedSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,sounds[@"Connected"]];
		else if( [sounds[@"Contact Signed On"] length] > 0 )
			_connectedSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,sounds[@"Contact Signed On"]];
	}
	else
	{
		NSLog(@"*** Unable to decode adium sound set at path %@",path);
	}
	
}

- (void)decodeBlackFireSoundSetAtPath:(NSString *)path
{
	NSString *informationPath = [[[NSString alloc] initWithFormat:@"%@/Info.plist",path] autorelease];
	NSDictionary *information = [[[NSDictionary alloc] initWithContentsOfFile:informationPath] autorelease];
	
	if( information )
	{
		NSString *name = [information[@"soundsetName"] retain];
		if( ! name )
			name = [@"Untitled soundset" retain];
		
		_name = name;
		
		[_receiveSoundPath release];
		_receiveSoundPath = nil;
		if( [information[@"receiveSound"] length] > 0 )
			_receiveSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,information[@"receiveSound"]];
		
		[_sendSoundPath release];
		_sendSoundPath = nil;
		if( [information[@"sendSound"] length] > 0 )
			_sendSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,information[@"sendSound"]];
		
		[_onlineSoundPath release];
		_onlineSoundPath = nil;
		if( [information[@"onlineSound"] length] > 0 )
			_onlineSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,information[@"onlineSound"]];
		
		[_offlineSoundPath release];
		_offlineSoundPath = nil;
		if( [information[@"offlineSound"] length] > 0 )
			_offlineSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,information[@"offlineSound"]];
		
		[_connectedSoundPath release];
		_connectedSoundPath = nil;
		if( [information[@"connectedSound"] length] > 0 )
			_connectedSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,information[@"connectedSound"]];
		else if( [information[@"onlineSound"] length] > 0 )
			_connectedSoundPath = [[NSString alloc] initWithFormat:@"%@/%@",path,information[@"onlineSound"]];

	}
	
}

@end
