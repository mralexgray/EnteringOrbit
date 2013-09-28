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

enum MASTER_EXEC {
    EXEC_DRAIN
};

@implementation AppDelegate {
    KSMessenger * messenger;
    
    int m_state;
    
    NSDictionary * paramDict;
    
    NSString * m_sourcetTarget;
    NSString * m_tailTarget;
    NSString * m_publishTarget;
    
    NSString * m_firstMessage;
    
    WebSocketClientController * m_client;
    
    NSTask * m_ssh;
    
    NSPipe * m_writePipe;//継続中に入力するのは不可能っぽい。
    
    FILE * fp;
    char m_buffer[BUFSIZ];
    
    NSString * m_indexStr;
    NSArray * m_peerErrors;
    
    int m_lineMax;
    int m_lineCount;
}



- (id) initAppDelegateWithParam:(NSDictionary * )dict {
    if (dict[@"-NSDocumentRevisionsDebugMode"]) {
        [self formatOutput:@"run -> exit"];
        exit(0);
    }
    
    if (dict[@"-XCTest"]) {
        return nil;
    }
    
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:EO_MASTER];
        
        m_state = STATE_READY;
        
        paramDict = [[NSDictionary alloc]initWithDictionary:dict];
        
        NSString * message = [self formatOutput:[NSString stringWithFormat:@"source-of-tail target required. %@ e.g. targetUserName@targetMachineName", KEY_SOURCETARGET]];
        NSAssert(dict[KEY_SOURCETARGET], message);
        m_sourcetTarget = [[NSString alloc]initWithString:paramDict[KEY_SOURCETARGET]];
        
        
        NSAssert1(dict[KEY_TAILTARGET], @"EnteringOrbit: tail target required. %@  e.g. ./something.txt", KEY_TAILTARGET);
        m_tailTarget = [[NSString alloc]initWithString:paramDict[KEY_TAILTARGET]];
        
        if (paramDict[KEY_PUBLISHTARGET]) m_publishTarget = [[NSString alloc]initWithString:paramDict[KEY_PUBLISHTARGET]];
        
        if (paramDict[KEY_INPUTFILE]) m_firstMessage = [self loadFile:paramDict[KEY_INPUTFILE]];
        

    }
    return self;
}

- (NSString * ) loadFile:(NSString * )filePath {
    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    

    if (readHandle) {
        NSData * data = [readHandle readDataToEndOfFile];
        NSString * fileContentsStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        [self formatOutput:[NSString stringWithFormat:@"EnteringOrbit: file contents is:%@", fileContentsStr]];
        
        return fileContentsStr;
    }
    NSAssert1(false, @"EnteringOrbit: failed to read -f %@", filePath);
    return nil;
}


- (void) applicationDidFinishLaunching:(NSNotification * )aNotification {
    [self run];
}

- (void) applicationWillTerminate:(NSNotification * )notification {
    NSLog(@"applicationWillTerminate hereComes %@", notification);
}



- (void) run {
    m_state = STATE_MONOCAST_CONNECTING;
    
    if (paramDict[KEY_PUBLISHTARGET]) {
        m_client = [[WebSocketClientController alloc]initWithMaster:[messenger myNameAndMID]];
        [m_client connect:m_publishTarget];
    } else {
        [self startDrain];
    }
}

- (void) startDrain {
    NSString * expect = @"/usr/bin/expect";
    
    //    http://www.math.kobe-u.ac.jp/~kodama/tips-expect.html
    
    //    expect
    //    -c "set timeout 30;
    //    spawn ssh mondogrosso@mondogrosso.201104392.members.btmm.icloud.com;
    //    send \"tail -f ./Desktop/130715_2_テロップ.txt\n\";
    //    interact;"
    
    // load errors-suffix
    m_peerErrors = [[NSArray alloc] initWithObjects:DEFINE_PEER_ERRORS];

    
    NSString * cHead = @"-c";
    
    // connect
    NSString * sourceTarget = [[NSString alloc]initWithFormat:@"spawn ssh %@;", m_sourcetTarget];
    
    
    // echo
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    m_indexStr = (NSString * )CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    NSString * echoPhrase = [[NSString alloc]initWithFormat:@"send \"echo %@\n\";", m_indexStr];
    
    
    // tail
    NSString * tailPhrase = [[NSString alloc]initWithFormat:@"send \"tail -f %@\n\";", m_tailTarget];
    
    
    
    /*
     combine lines
     */
    NSArray * expectParamArray = @[sourceTarget,
                                   echoPhrase,
                                   tailPhrase,
                                   @"interact;"
                                   ];
    
    NSArray * paramArray = @[cHead, [expectParamArray componentsJoinedByString:@"\n"]];
    
    
    
    // ssh task
    m_ssh = [[NSTask alloc]init];
    [m_ssh setLaunchPath:expect];
    [m_ssh setArguments:paramArray];
    
    m_writePipe = [[NSPipe alloc]init];
    NSPipe * readPipe = [[NSPipe alloc]init];
    
    [m_ssh setStandardInput:m_writePipe];
    [m_ssh setStandardOutput:readPipe];
    [m_ssh setStandardError:readPipe];
    [m_ssh launch];
    
    m_state = STATE_SOURCE_CONNECTING;

    
    m_lineMax = 0; m_lineCount = 0;
    if (paramDict[KEY_LIMIT]) m_lineMax = [paramDict[KEY_LIMIT] intValue];
    
    // read & publish
    NSFileHandle * publishHandle = [readPipe fileHandleForReading];
    
    fp = fdopen([publishHandle fileDescriptor], "r");
   
    [messenger callMyself:EXEC_DRAIN, nil];
}

/**
 tailが始まってしまったら、この関数はfgetsでロックが発生する。アプリケーション全体が止まる。whileループだろうが関係ない、
 fgetsで止まる。ふーむ、、別スレッドになってるはずだけど止まってしまう。いっそ別exeをrunするか。
 */
- (NSString * ) drain {
    while (fgets(m_buffer, BUFSIZ, fp)) {
        NSString * message = [NSString stringWithCString:m_buffer encoding:NSUTF8StringEncoding];
        [self formatOutput:[NSString stringWithFormat:@"message: %@", message]];
        
        switch (m_state) {
            case STATE_TAILING:{
                [self send:message];
                break;
            }
                
            case STATE_WAITING_TAILKEY:{//skip 1 line
                m_state = STATE_TAILING;
                break;
            }
                
            default:{//STATE_SOUCE_CONNECTED
                for (NSString * errorSuffix in m_peerErrors) {
                    if ([message hasPrefix:errorSuffix]) {
                        m_state = STATE_SOURCE_FAILED;
                        return [[NSString alloc]initWithFormat:@"%@ %@", errorSuffix, paramDict[KEY_SOURCETARGET]];
                    }
                }
                
                if ([message hasPrefix:m_indexStr]) m_state = STATE_WAITING_TAILKEY;
                break;
            }
        }
        m_lineCount++;
        
        if (m_lineMax != 0 && m_lineMax <= m_lineCount) m_state = STATE_SHUTDOWNED;
    }
    return nil;
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
            [self formatOutput:@"WebSocket connected to publishTarget."];
            m_state = STATE_MONOCAST_CONNECTED;
            
            if (paramDict[KEY_INPUTFILE]) {
                [self send:m_firstMessage];
            }
            
            [self startDrain];
            break;
        }
        case EXEC_FAILED:{
            m_state = STATE_MONOCAST_FAILED;
            [self formatOutput:[NSString stringWithFormat:@"failed to connect: %@", paramDict[KEY_PUBLISHTARGET]]];
            break;
        }
        default:
            break;
    }
    
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
        case EXEC_DRAIN:{
            NSString * errorMessage = [self drain];
            
            // 中止 or error
            if (m_state == STATE_SHUTDOWNED) {
                [self close];
                break;
            }
            if (m_state == STATE_MONOCAST_FAILED) {
                [self close];
                break;
            }
            if (m_state == STATE_SOURCE_FAILED) {
                [self formatOutput:errorMessage];

                [self close];
                break;
            }
            
            [messenger callMyself:EXEC_DRAIN,
             [messenger withDelay:0.001],
             nil];
            break;
        }
            
        default:
            break;
    }
}

/**
 特定のkey位置以降に開始されるsend
 */
- (void) send:(NSString * )message {
    if (paramDict[KEY_PUBLISHTARGET]){
        [m_client send:message];
    } else {
        [self formatOutput:message];
    }
}

- (NSString * ) formatOutput:(NSString * )message {
    if (paramDict[KEY_DEBUG]) {
        NSString * debugMessage = [[NSString alloc] initWithFormat:@"EnteringOrbit: debug: %@", message];
        NSLog(@"%@", debugMessage);
        return debugMessage;
    } else {
        NSString * logMessage = [[NSString alloc]initWithFormat:@"EnteringOrbit: %@", message];
        NSLog(@"%@", logMessage);
        return logMessage;
    }
}



- (void) close {
    // exit ssh
    [[m_writePipe fileHandleForWriting] closeFile];
    NSLog(@"or %hhd", [m_ssh isRunning]);
    
    [m_ssh waitUntilExit];
    NSLog(@"or2 %hhd", [m_ssh isRunning]);
    
    [m_client close];
    [messenger closeConnection];
}

@end
