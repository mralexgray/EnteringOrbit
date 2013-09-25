//
//  AppDelegate.m
//  EnteringOrbit
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "AppDelegate.h"

#import "KSMessenger.h"
#import "WebSocketClientController.h"



#define COMMAND_TAIL    (@"/usr/bin/tail")

@implementation AppDelegate {
    int m_state;
    
    NSDictionary * paramDict;
    
    NSString * m_connectTarget;
    NSString * m_tailTarget;
    
    WebSocketClientController * wsCont;
}


- (id) initAppDelegateWithParam:(NSDictionary * )dict {
    if (dict[@"-NSDocumentRevisionsDebugMode"]) {
        NSLog(@"debug run -> exit");
        exit(0);
    }
    
    if (dict[@"-XCTest"]) {
        return nil;
    }
    
    if (self = [super init]) {
        m_state = STATE_READY;
        
        paramDict = [[NSDictionary alloc]initWithDictionary:dict];
        
        NSAssert1(dict[KEY_CONNECTTARGET], @"connection target required. %@ targetUserName@targetMachineName", KEY_CONNECTTARGET);
        m_connectTarget = [[NSString alloc]initWithString:paramDict[KEY_CONNECTTARGET]];
        
        
        NSAssert1(dict[KEY_TAILTARGET], @"tail target required. %@ ./something.txt", KEY_TAILTARGET);
        m_tailTarget = [[NSString alloc]initWithString:paramDict[KEY_TAILTARGET]];

    }
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self run];
}



- (void) run {
    m_state = STATE_CONNECTING;
    
    NSString * expect = @"/usr/bin/expect";
    
    //    http://www.math.kobe-u.ac.jp/~kodama/tips-expect.html
    
    //    expect
    //    -c "set timeout 30;
    //    spawn ssh mondogrosso@mondogrosso.201104392.members.btmm.icloud.com;
    //    send \"tail -f ./Desktop/130715_2_テロップ.txt\n\";
    //    interact;"
    
    
    
    NSString * cHead = @"-c";
    
    // connect
    NSString * connectTarget = [[NSString alloc]initWithFormat:@"spawn ssh %@;", m_connectTarget];
    
    
    // echo
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString * uuidString = (NSString * )CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    NSString * echoPhrase = [[NSString alloc]initWithFormat:@"send \"echo %@\n\";", uuidString];
    
    
    // tail
    NSString * tailPhrase = [[NSString alloc]initWithFormat:@"send \"tail -f %@\n\";", m_tailTarget];
    
    
    
    /*
     combine lines
     */
    NSArray * expectParamArray = @[connectTarget,
                                   echoPhrase,
                                   tailPhrase,
                                   @"interact;"];
    
    NSArray * paramArray = @[cHead, [expectParamArray componentsJoinedByString:@"\n"]];
    
    
    
    // ssh task
    NSTask * ssh = [[NSTask alloc]init];
    [ssh setLaunchPath:expect];
    [ssh setArguments:paramArray];
    
    NSPipe * readPipe = [[NSPipe alloc]init];
    
    [ssh setStandardOutput:readPipe];
    [ssh setStandardError:readPipe];
    [ssh launch];
    
    
    
    
    // read & publish
    NSFileHandle * publishHandle = [readPipe fileHandleForReading];
    
    FILE * fp = fdopen([publishHandle fileDescriptor], "r");
    
    
    
    // start publish after echo +1
    char buffer[BUFSIZ];
    while(fgets(buffer, BUFSIZ, fp)) {
        
        NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        
        if (m_state == STATE_TAILING) {
            [self send:message];
        } else if ([message hasPrefix:uuidString]) {
            m_state = STATE_WAITING_TAILKEY;
        } else if (m_state == STATE_WAITING_TAILKEY) {
            m_state = STATE_TAILING;
        }
    }
}




- (BOOL) isConnecting {
    return (m_state == STATE_CONNECTING);
}

- (BOOL) isWaiting {
    return (m_state == STATE_WAITING_TAILKEY);
}


- (BOOL) isTailing {
    return (m_state == STATE_TAILING);
}


/**
 特定のkey位置以降に開始されるsend
 */
- (void) send:(NSString * )input {
    NSLog(@"読めるのかしら　%@", input);
}

@end
