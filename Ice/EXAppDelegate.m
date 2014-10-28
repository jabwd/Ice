//
//  EXAppDelegate.m
//  Ice
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import "EXAppDelegate.h"
#import "SKPacket.h"
#import "SKSession.h"
#import "NSData_SteamKitAdditions.h"
#import "SKAESEncryption.h"
#import "SKSentryFile.h"
#import "SKProtobufScanner.h"
#import "SKProtobufValue.h"
#import "SKProtobufCompiler.h"
#import "SKProtobufConstants.h"
#import "SKProtobufKey.h"

@implementation EXAppDelegate

- (void)dealloc
{
	[_session disconnect];
	[_session release];
	_session = nil;
	[_authcode release];
	_authcode = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.window.titlebarAppearsTransparent=YES;
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(notificationReceived:)
	 name:SKLoginFailedSteamGuardNotificationName object:nil];
	
	/*
	 cf5ba375723a8fac4ad0a267009159f92d106e84e1c5efc2e93413f2ac42f3af
	 91ef00e2a8a4cd95172844dae9b0ea46af60904b5f885e466cd6114989773822d6bc6b812906cbfd2ede52d667caf9c2510b5082f3aba152f976baffa8f7a052e3b44ff42f09fcfc490aab82128a5a8af70bcc668cd45849b476dc25eee06b75
	 
	 f8 33 32 03 c4 62 c9 6d d1 d6 46 fe 58 b0 d7 f7 ad f7 a5 8b 74 90 7c 64 b0 52 55 f3 b3 8a db bc 01 08 ab 80 04 10 8e e4 97 d0 07 28 eb 0d 32 07 65 6e 67 6c 69 73 68 38 b5 fe ff ff 0f 92 03 08 6e 75 6d 62 65 72 35 5f 9a 03 09 78 74 39 41 42 53 35 76 64 90 05 09
	 
	 8a150080 09000000 09000000 00010010 0108ab80 04108ee4 97d00728 eb0d3207 656e676c 69736838 b5feffff 0f920308 6e756d62 6572355f 9a030978 74394142 53357664 900509
	 */
	/*NSLog(@"%@", [[NSData dataFromByteString:@"010000800000000012b98080800035000000ef0200800e00000009ae63320a0100100110c9aace03083f4209676d61696c2e636f6d503fa101ae63320a01001001c00100c80100"] enhancedDescription]);
	
	NSLog(@"%@", [[NSData dataFromByteString:@"01000080 00000000 12b88080 80003400 0000ef02 00800d00 000009ae 63320a01 00100110 edcf2e08 3f420967 6d61696c 2e636f6d 503fa101 ae63320a 01001001 c00100c8 0100"] enhancedDescription]);
	
	[self connect:nil];*/
	
	
	/*NSLog(@"%@", [[NSData dataFromByteString:@"8a1500800900000009000000000100100108ab80041088e2b7850b28eb0d3207656e676c69736838b5feffff0f9203086e756d626572355f9a0309787439414253357664900509a205053132333435"] enhancedDescription]);
	SKProtobufScanner *scanner = [[SKProtobufScanner alloc] initWithData:[NSData dataFromByteString:@"8a1500800900000009000000000100100108ab80041088e2b7850b28eb0d3207656e676c69736838b5feffff0f9203086e756d626572355f9a0309787439414253357664900509a205053132333435"]];
	NSLog(@"%@ %@", scanner.header, scanner.body);
	[scanner release];*/
	
	SKProtobufValue *value = [[SKProtobufValue alloc] initWithData:[NSData dataFromByteString:@"eb898080"] type:WireTypeVarint];
	NSLog(@"%@ %lu", value.value, value.length);
	
	// 01000080 00000000 12b98080 80003500 0000
	//
	
	/*NSData *data = [NSData dataFromByteString:@"eb898080 001f8b08 00000000 0000ffd5 967f4c94 751cc73f cfdd311f 0e84a753 1a6bfeb8 0c030af3 4270ccd6 72151336 27246c9a 7f14a48c 1febc451 6a6db911 4872bf39 c0036425 1eb2161b 60b45191 2306a680 ae4db15b 3a602b36 4a0b5d5a 5bfe48fb 7ebedf7b eef95c1e cdf55f8c cffbfbfa be3f9fe7 fbf39edb ed028003 09501dc7 dae8de9d e9460914 4919bdf4 6b945127 eb8d0639 5591983e a500d355 5c1314e4 355c33b9 5ab83ec7 359deb23 5c37708d 5340d9f0 10f3e0a8 ff9b79ac 00705d17 e9dc6449 894e8c36 f7fc3430 6f585319 9d5768a9 ab3d2665 c5ef58b2 ffd5ca4d 15ef54bd 5b5162cd 5b672dcd da54915d 749ffd2d 2a93aae0 98a49e7e b7a4dbb2 79588231 09be973e bcd43efc fe95f18b 51e96c42 d0479ad0 b868cb5e eb1b2555 9926f65c caa22c9c 6e3b1441 99b407fe db531900 901ff943 612adefd f6fee2dd bbdeda58 6a2d2e7f f3999d95 56454a04 b3942259 200500e2 f400493a 60db0afb bfaeee6e 34ed2b56 05500d00 f7231f20 9862a263 ffe802fe 51d4b34e fce61e29 d4797626 4717ea3c dfbb57eb d80d535a a721d066 08958dce ce6a9d2b fe95513c a37b8cad e1d388fb 944101cc 4e2e9875 03406cc4 fb902553 920c091d e53985cb 591198d9 b958aae5 2c781172 a47cd87e 7626b5a8 f7ccf82b a6d5f2bd 92849399 2f15442c ebb6258b b264d979 549fb06c 920da764 e4169a21 052c1bd9 68ecb6f9 7817bbd3 78a10500 563cc4e9 4bac4efd 5fc6a075 c13d26c2 ef2c1f13 799746d3 d2bfd642 d2d3b313 8fab778b 9f76d3d2 8f1eddf6 fa8503e5 b9e1eee1 5505a905 8e5ba7c2 dd25d372 49f6ddf9 fa70f7cb 9af36979 d99ddf86 bbc9ad3b de3bdf7b 745bb83b e5b89c6b 185cbb2e dc2dd5a5 bde67d72 f5f270d7 f884ef85 d32be70f 86bbfbb6 0ebd3cb8 2f2a6c0d 66b6efad 91f7fd4b 43e7c819 7befc19c 15ac66fd bf9c9d59 5acf6e23 3ef2285d 733dae28 59a89ff0 71ce9d44 4556a8f0 458d50fb 097b63b4 ece02ad8 4dd8c559 384ece1e a2e2a907 6b8423b2 f4a9fa01 9ccbc6f5 41a68ea8 b17f81f5 426d9c1d 5c852358 a8c80aa5 59e1d8c6 066b16cb 2eae6eae 4eae82ed 9c85236a 44bd7068 8da81459 51e9e0cf 521dbcd3 fc8d41ee e33aeead 65f37ed2 842af824 f7cf72ff 04f7058b 1a1bf739 2bb64949 b107c3c1 5a0cf4b0 c540c6bc da226360 0e037d0c f4d4167d 8c7f7a98 471f5bcc 61601fc3 c9e6465f 6dd1c33c f6d5503d f491b15e 0dd5c316 03f36a60 5fad535b f4308f7d cad8c7c0 1cce8b39 b58f9eca d8b24862 efd69e88 6f8e3156 4e503a1b d89d241e 9a943258 5d59c477 90fd5c01 fef343e2 aae3aae7 6a5020a0 0758607c a39ca474 cf74f817 27e61b39 0f0f1d8a 0ab203df cb20bb08 fb7f735e 35047dcf e581bb2a fb6e7c1c 1ac73fed e950c79c e8acef52 f9f667ec 2d093e1b 20fedc71 adc65ef7 75680d1f 106e245c eb391d50 e70d3437 bbd5f103 a77ee853 d93b71b3 293638d7 ed1be36d 216e3977 531ff4fd 64cc019f b68641af b697fe76 8d1d23da 7eaf7dae 8d79cda6 adf95e9d 7686b513 5abd939c 61cd39cd 9f0bb842 e7396263 df94c1b5 f9c8da46 897f95cc d5ffa776 1717c8de 7f9c1aef 53cf61c8 a7ad7f86 f8ae9fe7 c6628273 75933b75 127fdaa5 adc789df 67c17a17 e1195233 42d85b7f a7c518ac 3f42d841 b89d7003 61276117 6137e1ef c8bdf793 f57b484d 23e126c2 cd840f13 f6116e21 dc4ab88d b09db25d dbaf9fdc 8b87f84e c22ec26e c25ec247 6e69f7db 407c7f3f ffacfe0d b222aae2 d10c0000"];
	[data writeToFile:@"/Users/jabwd/Desktop/test.zip" atomically:NO];
	data = [NSData dataWithContentsOfFile:@"/Users/jabwd/Desktop/test.bin"];
	NSLog(@"%@", data);
	
	SKPacket *test = [SKPacket packetByDecodingTCPBuffer:data sessionKey:nil error:nil];
	NSLog(@"%@", test);*/
}

- (void)notificationReceived:(NSNotification *)notification
{
	if( [notification.name isEqualToString:SKLoginFailedSteamGuardNotificationName] )
	{
		NSString *email = [notification userInfo][@"email"];
		EXSteamGuardWindowController *controller = [[EXSteamGuardWindowController alloc] initWithEmailName:email];
		controller.delegate = self;
		[controller.window makeKeyAndOrderFront:self];
	}
}

- (void)steamGuardEndedWithCode:(NSString *)code controller:(EXSteamGuardWindowController *)controller
{
	controller.delegate = nil;
	[controller.window close];
	[controller release];
	[_authcode release];
	_authcode = [code retain];
	[self connect:nil];
}

- (IBAction)scanPacketData:(id)sender
{
	SKProtobufScanner *scanner = [[SKProtobufScanner alloc] initWithData:[NSData dataFromByteString:[_packetDataField stringValue]]];
	NSLog(@"%@ %@", scanner.header, scanner.body);
	[scanner release];
}

- (IBAction)decryptData:(id)sender
{
	NSData *data		= [NSData dataFromByteString:[_sessionKeyField stringValue]];
	NSData *packetData	= [NSData dataFromByteString:[_dataField stringValue]];
	
	NSData *decrypted = [SKAESEncryption decryptPacketData:packetData key:data];
	NSLog(@"Decrypted: %@", decrypted);
}

- (IBAction)encryptData:(id)sender
{
	NSData *data			= [NSData dataFromByteString:[_sessionKeyField stringValue]];
	NSData *dataToEncrypt	= [NSData dataFromByteString:[_dataField stringValue]];
	
	NSData *encrypted = [SKAESEncryption encryptPacketData:dataToEncrypt key:data];
	NSLog(@"Encrypted: %@", encrypted);
}

- (IBAction)connect:(id)sender
{
	if( _session )
	{
		DLog(@"Already connected!");
		return;
	}
	_session = [[SKSession alloc] init];
	_session.delegate = self;
	[_session connect];
	
	[_sessionKeyField setStringValue:[[_session.sessionKey description] substringWithRange:NSMakeRange(1, 32)]];
}

- (IBAction)disconnect:(id)sender
{
	[_session disconnect];
	[_session release];
	_session = nil;
}

#pragma mark - SKSession delegate

- (void)sessionChangedStatus:(SKSession *)session
{
	DLog(@"Session changed: %u", session.status);
	switch((SKSessionStatus)session.status)
	{
		case SKSessionStatusOffline:
		{
			_session.delegate = nil;
			[_session release];
			_session = nil;
		}
			break;
			
		default:
			break;
	}
}

- (NSString *)username
{
	return [_usernameField stringValue];
}

- (NSString *)password
{
	return [_passwordField stringValue];
}

- (NSString *)steamGuard
{
	return _authcode;
}

@end
