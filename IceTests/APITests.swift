//
//  APITests.swift
//  Ice
//
//  Created by Antwan van Houdt on 11/08/15.
//  Copyright © 2015 Exurion. All rights reserved.
//

import XCTest

class APITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
	
	func testCGEventSource()
	{
		XCTAssert(CGEventType.TapDisabledByUserInput.rawValue == (~0))
	}

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
