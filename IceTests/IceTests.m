//
//  IceTests.m
//  IceTests
//
//  Created by Antwan van Houdt on 15/09/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKAESEncryption.h"

@interface IceTests : XCTestCase

@end

@implementation IceTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEncryption
{
	NSData *key = [SKAESEncryption generateRandomData:32];
	NSData *iv = [key subdataWithRange:NSMakeRange(0, 16)];
	
	XCTAssert(([iv length] == 16), @"IV is not of length 16");
	XCTAssert(([key length] == 32), @"Key is not of length 32");
	
	//NSString *bla = @"Hello World!";
	//NSData *encrypted = [SKAESEncryption encryptData:[bla dataUsingEncoding:NSUTF8StringEncoding] withKey:key iv:iv];
	//NSData *decrypted = [SKAESEncryption decryptData:encrypted withKey:key iv:iv];
	//NSString *str = [[NSString alloc] initWithData:[decrypted subdataWithRange:NSMakeRange(0, [bla length])] encoding:NSUTF8StringEncoding];
	
	//XCTAssert(([bla isEqualToString:str]), @"Decrypted string is not the same as the original");
}

- (void)testExample
{
	
}

@end
