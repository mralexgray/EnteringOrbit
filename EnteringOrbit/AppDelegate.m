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

#define EO_MASTER   (@"EO_MASTER")

#define COMMAND_TAIL    (@"/usr/bin/tail")

@implementation AppDelegate {
    KSMessenger * messenger;
    
    int m_state;
    
    NSDictionary * paramDict;
    
    NSString * m_sourcetTarget;
    NSString * m_tailTarget;
    NSString * m_publishTarget;
    
    WebSocketClientController * m_client;
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
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:EO_MASTER];
        
        m_state = STATE_READY;
        
        paramDict = [[NSDictionary alloc]initWithDictionary:dict];
        
        NSAssert1(dict[KEY_SOURCETARGET], @"source-of-tail target required. %@ e.g. targetUserName@targetMachineName", KEY_SOURCETARGET);
        m_sourcetTarget = [[NSString alloc]initWithString:paramDict[KEY_SOURCETARGET]];
        
        
        NSAssert1(dict[KEY_TAILTARGET], @"tail target required. %@  e.g. ./something.txt", KEY_TAILTARGET);
        m_tailTarget = [[NSString alloc]initWithString:paramDict[KEY_TAILTARGET]];
        
        NSAssert1(dict[KEY_PUBLISHTARGET], @"connect target required. %@ e.g. ws://s.o.m.ewhere:someport", KEY_PUBLISHTARGET);
        m_publishTarget = [[NSString alloc]initWithString:paramDict[KEY_PUBLISHTARGET]];

    }
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self run];
}



- (void) run {
    m_state = STATE_MONOCAST_CONNECTING;
    
    m_client = [[WebSocketClientController alloc]initWithTargetAddress:@"" withMaster:[messenger myNameAndMID]];
    [m_client connect:m_publishTarget];
}

- (void) drainViaTail {

    NSString * expect = @"/usr/bin/expect";
    
    //    http://www.math.kobe-u.ac.jp/~kodama/tips-expect.html
    
    //    expect
    //    -c "set timeout 30;
    //    spawn ssh mondogrosso@mondogrosso.201104392.members.btmm.icloud.com;
    //    send \"tail -f ./Desktop/130715_2_テロップ.txt\n\";
    //    interact;"
    
    
    NSString * cHead = @"-c";
    
    // connect
    NSString * sourceTarget = [[NSString alloc]initWithFormat:@"spawn ssh %@;", m_sourcetTarget];
    
    
    // echo
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString * indexStr = (NSString * )CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    NSString * echoPhrase = [[NSString alloc]initWithFormat:@"send \"echo %@\n\";", indexStr];
    
    
    // tail
    NSString * tailPhrase = [[NSString alloc]initWithFormat:@"send \"tail -f %@\n\";", m_tailTarget];
    
    
    
    /*
     combine lines
     */
    NSArray * expectParamArray = @[sourceTarget,
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
    
    m_state = STATE_SOURCE_CONNECTING;

    
    // read & publish
    NSFileHandle * publishHandle = [readPipe fileHandleForReading];
    
    char buffer[BUFSIZ];
    
    int limitLineNum = [paramDict[KEY_LIMIT] intValue];
    
    FILE * fp = fdopen([publishHandle fileDescriptor], "r");
    
    long line = 0;
    
    while(fgets(buffer, BUFSIZ, fp)) {
        NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        if (paramDict[KEY_DEBUG]) NSLog(@"message %@", message);
        switch (m_state) {
            case STATE_TAILING:{
                [self send:message];
                line++;
                break;
            }
                
            case STATE_WAITING_TAILKEY:{//skip 1 line
                m_state = STATE_TAILING;
                break;
            }
                
            default:{//STATE_SOUCE_CONNECTED
                if ([message hasPrefix:indexStr]) m_state = STATE_WAITING_TAILKEY;
                break;
            }
        }
        
        if (limitLineNum != 0 && limitLineNum < line) {
            // break loop.
            break;
        }
    }

}


- (BOOL) status {
    return m_state;
}


- (BOOL) isTailing {
    return (m_state == STATE_TAILING);
}

- (BOOL) isConnectedToServer {
    return [m_client isConnected];
}



- (void) receiver:(NSNotification * ) notif {
    switch ([messenger execFrom:EO_WSCONT viaNotification:notif]) {
        case EXEC_CONNECTED:{
            if (paramDict[KEY_DEBUG]) NSLog(@"WebSocket connected to publishTarget.");
            m_state = STATE_MONOCAST_CONNECTED;
            [self drainViaTail];
            break;
        }
        case EXEC_FAILED:{
            m_state = STATE_MONOCAST_FAILED;
            break;
        }
        default:
            break;
    }
}



/**
 特定のkey位置以降に開始されるsend
 */
- (void) send:(NSString * )input {
    if (paramDict[KEY_DEBUG]) NSLog(@"読sending　%@", input);
    [m_client send:input];
}

- (void) close {
    [m_client close];
    [messenger closeConnection];
}
@end
