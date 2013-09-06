//
//  Ishimura_Tests.m
//  Ishimura Tests
//
//  Created by Maksym on 9/5/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CMMenu.h"

@interface Ishimura_Tests : XCTestCase

@end

@implementation Ishimura_Tests

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
