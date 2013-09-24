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


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

- (id) initAppDelegateWithParam:(NSDictionary * )dict;

@end
