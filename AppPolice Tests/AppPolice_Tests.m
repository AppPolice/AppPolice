//
//  AppPolice_Tests.m
//  AppPolice Tests
//
//  Created by Maksym on 9/5/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ChromeMenu/ChromeMenu.h>

@interface AppPolice_Tests : XCTestCase

@end

@implementation AppPolice_Tests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testMenuIsCreating {
	CMMenu *menu = [[CMMenu alloc] init];
	XCTAssertNotNil(menu, @"Menu could not be created.");
}

@end
