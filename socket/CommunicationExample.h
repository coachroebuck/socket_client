//
//  CommunicationExample.h
//  socket
//
//  Created by Michael Roebuck on 12/28/16.
//  Copyright © 2016 Michael Roebuck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerExample.h"

@interface CommunicationExample : NSObject

@property (nonatomic, weak) id<ServerResponseDelegate> delegate;

- (void) initNetworkCommunication:(NSString *)ip port:(UInt32)port;
- (void)joinChat:(NSString *)deviceName;
- (void)sendMessage:(NSString *)message;

@end
