//
//  SocketClient.h
//  socket
//
//  Created by Michael Roebuck on 1/9/17.
//  Copyright © 2017 Michael Roebuck. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SocketClientDelegate <NSObject>

- (void) onServerResponse:(NSString *)response;
- (void) onSocketClosed;

@end

@interface SocketClient : NSObject

+ (instancetype) instanceWithDelegate:(id)delegate;

- (BOOL) start:(NSString *)server_ip
   port_number:(NSInteger)port_number;

- (BOOL) read;

- (BOOL) stop;

- (BOOL) write:(NSString *)message;

@end
