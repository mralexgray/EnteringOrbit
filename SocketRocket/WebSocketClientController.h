//
//  WebSocketClientController.h
//  WebAntenna
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

#define EO_WSCONT (@"EO_WSCONT")

enum EXEC {
    EXEC_CONNECT,
    EXEC_CONNECTED,
    EXEC_SEND
};

@interface WebSocketClientController : NSObject <SRWebSocketDelegate>

- (id) initWithTargetAddress:(NSString * )address withMaster:(NSString * )masternameAndId;

- (BOOL) connected;


- (void) connect:(NSString * )url;
- (void) send:(NSString * )message;

@end
