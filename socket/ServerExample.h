//
//  ServerExample.h
//  socket
//
//  Created by Michael Roebuck on 12/28/16.
//  Copyright © 2016 Michael Roebuck. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServerResponseDelegate <NSObject>

- (void) onResponse:(NSString *)response;

@end

@interface ServerExample : NSObject

+ (void) runServer:(id<ServerResponseDelegate>)delegate port:(NSInteger)port;
+ (NSString *) runClient:(NSString *)outgoingIpAddress
      outgoingPort:(NSInteger)outgoingPort
 responseIpAddress:(NSString *)responseIpAddress
      responsePort:(NSInteger)responsePort
           message:(NSString *)message;
+ (NSString *)ipAddress;
@end
