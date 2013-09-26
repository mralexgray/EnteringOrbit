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
#define TEST_LIMIT_5   ([NSNumber numberWithInt:5])

@interface EnteringOrbitTests : XCTestCase

@end

@implementation EnteringOrbitTests {
    AppDelegate * delegate;
}

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    [delegate close];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void) testRunWithValidParam {
    NSDictionary * paramDict = @{
                                 KEY_SOURCETARGET:TEST_SOURCE_TARGET,
                                 KEY_TAILTARGET:TEST_TAIL_TARGET,
                                 KEY_PUBLISHTARGET:TEST_PUBLISH_TARGET};
    
    delegate = [[AppDelegate alloc] initAppDelegateWithParam:paramDict];
}


- (void) testRunWithValidParamWait1TailEmit {
    NSDictionary * paramDict = @{
                                 KEY_SOURCETARGET:TEST_SOURCE_TARGET,
                                 KEY_TAILTARGET:TEST_TAIL_TARGET,
                                 KEY_PUBLISHTARGET:TEST_PUBLISH_TARGET,
                                 KEY_LIMIT:TEST_LIMIT_5};
    
    delegate = [[AppDelegate alloc] initAppDelegateWithParam:paramDict];
    [delegate run];
    
    // wait for line-tailed
    while ([delegate status] < STATE_TAILING) {
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssert([delegate isTailing], @"not tailing");
}

- (void) testWebSocketClientAwaken {
    NSDictionary * paramDict = @{
                                 KEY_SOURCETARGET:TEST_SOURCE_TARGET,
                                 KEY_TAILTARGET:TEST_TAIL_TARGET,
                                 KEY_PUBLISHTARGET:TEST_PUBLISH_TARGET,
                                 KEY_LIMIT:TEST_LIMIT_5};
    
    delegate = [[AppDelegate alloc] initAppDelegateWithParam:paramDict];
    [delegate run];
    
    // wait for line-tailed
    
    XCTAssert([delegate isConnectedToServer], @"not connected");
}


- (void) testWebSocnetClientConnectFailedThenKill {
    NSDictionary * paramDict = @{
                                 KEY_SOURCETARGET:TEST_SOURCE_TARGET,
                                 KEY_TAILTARGET:TEST_TAIL_TARGET,
                                 KEY_PUBLISHTARGET:TEST_DUMMY_PUBLISH_TARGET,
                                 KEY_LIMIT:TEST_LIMIT_5};
    
    delegate = [[AppDelegate alloc] initAppDelegateWithParam:paramDict];
    [delegate run];
    
    // wait for line-tailed
    while ([delegate status] < STATE_MONOCAST_FAILED) {
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssert([delegate status] == STATE_MONOCAST_FAILED, @"not match, %d", [delegate status]);
}

- (void) testPeerConnectFailedThenKill {
    NSDictionary * paramDict = @{
                                 KEY_SOURCETARGET:TEST_DUMMY_SOURCE_TARGET,
                                 KEY_TAILTARGET:TEST_TAIL_TARGET,
                                 KEY_PUBLISHTARGET:TEST_PUBLISH_TARGET,
                                 KEY_LIMIT:TEST_LIMIT_5};
    
    delegate = [[AppDelegate alloc] initAppDelegateWithParam:paramDict];
    [delegate run];
    
    // wait for line-tailed
    while ([delegate status] < STATE_SOURCE_FAILED) {
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssert([delegate status] == STATE_SOURCE_FAILED, @"not match, %d", [delegate status]);
}



@end
