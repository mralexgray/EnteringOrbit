//
//  AppDelegate.h
//  EnteringOrbit
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Cocoa/Cocoa.h>



#define KEY_TAILTARGET      (@"-t")
#define KEY_CONNECTTARGET   (@"-c")
#define KEY_DEBUG           (@"--d")

enum STATE {
    STATE_READY,
    STATE_CONNECTING,
    STATE_FAILED_TO_CONNECT,
    
    STATE_WAITING_TAILKEY,
    
    STATE_TAILING,
    STATE_FAILED_TO_TAIL
};

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

- (id) initAppDelegateWithParam:(NSDictionary * )dict;
- (void) run;


- (BOOL) isConnecting;
- (BOOL) isWaiting;
- (BOOL) isTailing;

@end
