//
//  WebSocketClientController.m
//  WebAntenna
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "WebSocketClientController.h"
#import "KSMessenger.h"

@implementation WebSocketClientController {
    KSMessenger * messenger;
    SRWebSocket * ws;
}

- (id) initWithMaster:(NSString * )masternameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:EO_WSCONT];
        [messenger connectParent:masternameAndId];
    }
    return self;
}

- (void) receiver:(NSNotification * )notif {}


- (void) connect:(NSString * )url {
    ws = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:url]];
    [ws setDelegate:self];
    [ws open];
}


- (BOOL) isConnected {
    if (ws) return true;
    return false;
}



- (void) send:(NSString * )message {
    [ws send:message];
}

- (void)webSocket:(SRWebSocket * )webSocket didReceiveMessage:(id)message {}

- (void)webSocketDidOpen:(SRWebSocket * )webSocket {
    [messenger callParent:EXEC_CONNECTED, nil];
}

- (void)webSocket:(SRWebSocket * )webSocket didFailWithError:(NSError * )error {
    [messenger callParent:EXEC_FAILED, nil];
}

- (void)webSocket:(SRWebSocket * )webSocket didCloseWithCode:(NSInteger)code reason:(NSString * )reason wasClean:(BOOL)wasClean {}

- (void) close {
    [ws close];
    [messenger closeConnection];
}
@end
