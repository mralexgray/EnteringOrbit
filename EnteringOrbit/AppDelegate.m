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


@implementation AppDelegate {
    NSDictionary * paramDict;
    
    WebSocketClientController * wsCont;
}


- (id) initAppDelegateWithParam:(NSDictionary * )dict {
    if (self = [super init]) {
        paramDict = [[NSDictionary alloc]initWithDictionary:dict];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSFileHandle * fHand = [NSFileHandle fileHandleForWritingAtPath:@"/Users/highvision/Desktop/testing/test.txt"];
    NSAssert(fHand, @"nil");
    /**
     NSTaskでsshで繋いでlogがあるところまで移動してログの内容をtailしてWebSocketで出力する。
     プロセスの開始時にWebSocketクライアントになる。
     */
    
    
    NSArray * paramArray = @[@"-l", @"sassembla", @"192.168.11.6"];
    //    NSArray * paramArray = @[@"-2", @"-6", @"mondogrosso@mondogrosso.201104392.members.btmm.icloud.com"];
    
    NSPipe * pipeFromSSH = [[NSPipe alloc]init];
    
    NSTask * ssh = [[NSTask alloc]init];
    [ssh setLaunchPath:@"/usr/bin/ssh"];
    [ssh setArguments:paramArray];
    [ssh setStandardOutput:fHand];
    [ssh launch];
    
    NSLog(@"over");
    
    
    
    //    ssh
    
    //    NSTask * tail = [[NSTask alloc]init];
    //    [tail setLaunchPath:@"ls"];
    ////    [tail setArguments:paramArray];
    //    [tail setStandardInput:pipeFromSSH];
    //
    //    [tail launch];
    
    
    
}

@end
