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

#define KEY_LIMITSEC    (@"-l")
#define KEY_TARGET      (@"-t")

#define COMMAND_TAIL    (@"/usr/bin/tail")

@implementation AppDelegate {
    NSDictionary * paramDict;
    
    WebSocketClientController * wsCont;
}


- (id) initAppDelegateWithParam:(NSDictionary * )dict {
    if (self = [super init]) {
        //        paramDict = [[NSDictionary alloc]initWithDictionary:dict];
        paramDict = @{KEY_TARGET:@"mondogrosso@mondogrosso.201104392.members.btmm.icloud.com"};
    }
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSError * error;
    
    NSString * tempLogFilePath = [[NSString alloc]initWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"temp.txt"];
    
    // if exist, delete
    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:tempLogFilePath];
    if (readHandle) {// delete
        [fileManager removeItemAtPath:tempLogFilePath error:&error];
    }
    
    
    // create temporary output
    bool makeTempFile = [fileManager createFileAtPath:tempLogFilePath contents:nil attributes:nil];
    NSAssert1(makeTempFile, @"failed to make tempfile @ %@, please chech chmod", tempLogFilePath);
    
    NSFileHandle * outhand = [NSFileHandle fileHandleForWritingAtPath:tempLogFilePath];
    NSAssert(outhand, @"nil");
    
    
    
    /**
     NSTaskでsshで繋いでlogがあるところまで移動してログの内容をtailしてWebSocketで出力する。
     プロセスの開始時にWebSocketクライアントになる。
     */
    NSString * expect = @"/usr/bin/expect";
    
    //    http://www.math.kobe-u.ac.jp/~kodama/tips-expect.html
    
    //    expect
    //    -c "set timeout 30;
    //    spawn ssh mondogrosso@mondogrosso.201104392.members.btmm.icloud.com;
    //    send \"tail -f ./Desktop/130715_2_テロップ.txt\n\";
    //    interact;"
    
    NSString * cHead = @"-c";
    
    int timeLimitSec = 30;
    if (paramDict[KEY_LIMITSEC]) timeLimitSec = [paramDict[KEY_LIMITSEC] intValue];
    NSString * timeLimitPhrase = [[NSString alloc] initWithFormat:@"set timeout %d;", timeLimitSec];
    
    NSAssert1(paramDict[KEY_TARGET], @"target required. %@ targetUserName@targetMachineName", KEY_TARGET);
    
    NSString * connectTarget = [[NSString alloc]initWithFormat:@"spawn ssh %@;" ,paramDict[KEY_TARGET]];
    
    
    /*
     combine lines
     */
    NSArray * expectParamArray = @[timeLimitPhrase,
                                   connectTarget,
                                   @"send \"tail -f ./Desktop/testLog.txt\n\";",
                                   @"interact;"];
    
    NSArray * paramArray = @[cHead, [expectParamArray componentsJoinedByString:@"\n"]];
    
    
    // tail task
    NSTask * tail = [[NSTask alloc]init];
    [tail setLaunchPath:COMMAND_TAIL];
    [tail setArguments:@[@"-f", tempLogFilePath]];
    [tail launch];
    
    
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
    
    FILE * my_file_pointer = fdopen([publishHandle fileDescriptor], "r");
    
    
    char buffer[BUFSIZ];
    while(fgets(buffer, BUFSIZ, my_file_pointer)) {
        NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        [self send:message];
    }
    
}

- (void) send:(NSString * )input {
    NSLog(@"読めるのかしら　%@", input);
}


- (void) update:(NSNotification * )update {
    if ([update name] == NSApplicationWillUpdateNotification) return;
    if ([update name] == NSTextInputContextKeyboardSelectionDidChangeNotification) return;
    if ([update name] == NSApplicationDidUpdateNotification) return;
    if ([update name] == NSApplicationDidBecomeActiveNotification) return;
    if ([update name] == NSApplicationWillBecomeActiveNotification) return;
    if ([update name] == NSApplicationDidResignActiveNotification) return;
    if ([update name] == NSApplicationWillResignActiveNotification) return;
    
    
    NSLog(@"update %@", update);//もしかしたらキャッチできるかもしれない。
}

@end
