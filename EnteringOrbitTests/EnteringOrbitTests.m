//
//  EnteringOrbitTests.m
//  EnteringOrbitTests
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppDelegate.h"

#import "TestParams.h"

@interface EnteringOrbitTests : XCTestCase

@end

@implementation EnteringOrbitTests {
    AppDelegate * delegate;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testRunWithValidParam {
    NSDictionary * paramDict = @{
                                 KEY_CONNECTTARGET:TEST_CONNECT_TARGET,
                                 KEY_TAILTARGET:TEST_TAIL_TARGET};
    
    delegate = [[AppDelegate alloc] initAppDelegateWithParam:paramDict];
}




@end
