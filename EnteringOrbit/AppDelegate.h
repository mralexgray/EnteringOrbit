//
//  AppDelegate.h
//  EnteringOrbit
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Cocoa/Cocoa.h>



#define KEY_TAILTARGET      (@"-t")
#define KEY_SOURCETARGET    (@"-s")
#define KEY_CONNECTTARGET   (@"-c")
#define KEY_DEBUG           (@"--d")
#define KEY_LIMIT           (@"--l")

enum STATE {
    STATE_READY,
    
    STATE_MONOCAST_CONNECTING,
    STATE_MONOCAST_CONNECTED,
    STATE_MONOCAST_FAILED,

    STATE_SOURCE_CONNECTING,
    STATE_SOURCE_CONNECTED,
    STATE_SOURCE_FAILED,
    
    STATE_WAITING_TAILKEY,
    
    STATE_TAILING,
    STATE_FAILED_TO_TAIL
};

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

- (id) initAppDelegateWithParam:(NSDictionary * )dict;
- (void) run;
- (void) drainViaTail;

- (BOOL) status;

- (BOOL) isTailing;

- (BOOL) isConnectedToServer;

- (void) close;

@end
