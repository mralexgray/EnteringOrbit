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
}



- (id) initAppDelegateWithParam:(NSDictionary * )dict {
    if (dict[@"-NSDocumentRevisionsDebugMode"]) {
        [self getOutputStr:@"debug run -> exit"];
        exit(0);
    }
    
    if (dict[@"-XCTest"]) {
        return nil;
    }
    
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:EO_MASTER];
        
        m_state = STATE_READY;
        
        paramDict = [[NSDictionary alloc]initWithDictionary:dict];
        
        NSString * message = [self getOutputStr:[NSString stringWithFormat:@"source-of-tail target required. %@ e.g. targetUserName@targetMachineName", KEY_SOURCETARGET]];
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
        if (paramDict[KEY_DEBUG]) NSLog(@"EnteringOrbit: file contents is:%@", fileContentsStr);
        
        return fileContentsStr;
    }
    NSAssert1(false, @"EnteringOrbit: failed to read -f %@", filePath);
    return nil;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self run];
}



- (void) run {
    m_state = STATE_MONOCAST_CONNECTING;
    
    if (paramDict[KEY_PUBLISHTARGET]) {
        m_client = [[WebSocketClientController alloc]initWithTargetAddress:@"" withMaster:[messenger myNameAndMID]];
        [m_client connect:m_publishTarget];
    } else {
        [messenger callMyself:EXEC_DRAIN,
         [messenger withDelay:0.01],
         nil];
    }
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
    m_ssh = [[NSTask alloc]init];
    [m_ssh setLaunchPath:expect];
    [m_ssh setArguments:paramArray];
    
    NSPipe * writePipe = [[NSPipe alloc]init];
    NSPipe * readPipe = [[NSPipe alloc]init];
    
    [m_ssh setStandardInput:writePipe];
    [m_ssh setStandardOutput:readPipe];
    [m_ssh setStandardError:readPipe];
    [m_ssh launch];
    
    m_state = STATE_SOURCE_CONNECTING;

    // read & publish
    NSFileHandle * publishHandle = [readPipe fileHandleForReading];
    
    // load errors-suffix
    NSArray * peerErrors = [[NSArray alloc] initWithObjects:DEFINE_PEER_ERRORS];
    NSString * m_error;
    
    char buffer[BUFSIZ];
    
    int limitLineNum = [paramDict[KEY_LIMIT] intValue];
    
    FILE * fp = fdopen([publishHandle fileDescriptor], "r");
    
    long line = 0;
    
    while(fgets(buffer, BUFSIZ, fp)) {
        
        NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        [self getOutputStr:[NSString stringWithFormat:@"message: %@", message]];
        
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
                for (NSString * errorSuffix in peerErrors) {
                    if ([message hasPrefix:errorSuffix]) {
                        m_state = STATE_SOURCE_FAILED;

                        NSLog(@"    %@",[self getOutputStr:@"start tailing"]);
                        m_error = [[NSString alloc]initWithFormat:@"%@ %@", errorSuffix, paramDict[KEY_SOURCETARGET]];
                    }
                }
                
                if ([message hasPrefix:indexStr]) {
                    m_state = STATE_WAITING_TAILKEY;
                    NSLog(@"    %@",[self getOutputStr:@"start tailing"]);
                }
                break;
            }
        }
        
        if (limitLineNum != 0 && limitLineNum < line) break;
        if (m_state == STATE_MONOCAST_FAILED) break;
        if (m_state == STATE_SOURCE_FAILED) break;
        
    }
    
    // output message
    switch (m_state) {
        case STATE_SOURCE_FAILED:{
            [self getOutputStr:m_error];
            break;
        }
        default:
            break;
    }
    
    // kill task
    [[writePipe fileHandleForWriting] closeFile];
    
    [m_ssh waitUntilExit];
    
    // dead
    [self close];
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
            [self getOutputStr:@"WebSocket connected to publishTarget."];
            m_state = STATE_MONOCAST_CONNECTED;
            
            if (paramDict[KEY_INPUTFILE]) {
                [self send:m_firstMessage];
            }
            
            [self drainViaTail];
            break;
        }
        case EXEC_FAILED:{
            m_state = STATE_MONOCAST_FAILED;
            [self getOutputStr:[NSString stringWithFormat:@"failed to connect: %@", paramDict[KEY_PUBLISHTARGET]]];
            break;
        }
        default:
            break;
    }
    
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
        case EXEC_DRAIN:
            [self drainViaTail];
            break;
            
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
        [self getOutputStr:message];
    }
}

- (NSString * ) getOutputStr:(NSString * )message {
    NSString * logMessage;
    if (paramDict[KEY_DEBUG]) {
        logMessage = [[NSString alloc] initWithFormat:@"EnteringOrbit: debug: %@", message];
        NSLog(@"%@",logMessage);

    } else {
        logMessage = [[NSString alloc]initWithFormat:@"EnteringOrbit: %@", message];

    }
    return logMessage;
}

- (void) close {
    [m_client close];
    [messenger closeConnection];
}

@end
