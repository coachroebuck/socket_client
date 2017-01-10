//
//  SocketClient.m
//  socket
//
//  Created by Michael Roebuck on 1/9/17.
//  Copyright © 2017 Michael Roebuck. All rights reserved.
//

#import "SocketClient.h"

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/socket.h>
#include <resolv.h>
#include <arpa/inet.h>
#include <stdarg.h>
#include <errno.h>
#include <string.h>

#define PORT_TIME       13              /* "time" (not available on RedHat) */
#define MAXBUF          4096

@interface SocketClient ()
{
    int sockfd;
    struct sockaddr_in dest;
    char buffer[MAXBUF];
    int bytes_read;
}

@property (nonatomic, weak) id<SocketClientDelegate> delegate;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) long arg;

@end

@implementation SocketClient

+ (instancetype) instanceWithDelegate:(id)delegate {
    SocketClient * client = [SocketClient new];
    client.delegate = delegate;
    client.isRunning = false;
    client.arg = 0;
    return client;
}

- (BOOL) start:(NSString *)server_ip
   port_number:(NSInteger)port_number {
    
    /*---Create socket for streaming---*/
    printf("creating socket...\n");
    if ( (sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0 )
    {
        perror("Socket");
        exit(errno);
    }
    
    /*---Initialize server address/port struct---*/
    printf("Initializing server address/port...\n");
    bzero(&dest, sizeof(dest));
    dest.sin_family = AF_INET;
    if ( inet_aton(server_ip.UTF8String, &dest.sin_addr.s_addr) == 0 )
    {
        perror("Failed to initialize server.");
        return false;
    }
    dest.sin_port = htons(port_number);
    
//    if ( (self.arg = fcntl(sockfd, F_GETFL, NULL)) < 0)
//    {
//        perror("Failed to initialize connection.");
//        return false;
//    }
//    else
//    {
//        self.arg |= O_NONBLOCK;
//        if( fcntl(sockfd, F_SETFL, self.arg) < 0)
//        {
//            perror("Failed to set socket to non-blocking. %s");
//            return false;
//        }
//    }
    
    /*---Connect to server---*/
    printf("connecting to server...\n");
    if ( connect(sockfd, (struct sockaddr *)&dest, sizeof(dest)) != 0 )
    {
        perror("Error Connecting to server");
        return false;
    }
    
    printf("CONNECTED!!...\n");
    
    int opt = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, &opt, sizeof(opt)))
    {
        perror("Failed to set this socket to keep alive");
        return false;
    }

    self.isRunning = true;
    return true;
}

- (BOOL) read {
    
    printf("Beginning to read...\n");
    do
    {
        bzero(buffer, MAXBUF);
        bytes_read = recv(sockfd, buffer, MAXBUF, 0);
        if ( bytes_read > 0 && self.isRunning) {
            printf("%s", buffer);
            if([self.delegate respondsToSelector:@selector(onServerResponse:)]) {
                [self.delegate onServerResponse:[NSString stringWithUTF8String:buffer]];
            }
        }
    }
    while ( bytes_read > 0 && self.isRunning);

    self.isRunning = false;
    
    return true;
}

- (BOOL) stop {
    printf("closing socket...\n");
    self.isRunning = false;
    close(sockfd);
    
    if([self.delegate respondsToSelector:@selector(onSocketClosed)]) {
        [self.delegate onSocketClosed];
    }
    return true;
}

- (BOOL) write:(NSString *)message {
    
    /*---If there is a message to send server, send it with a '\n' (newline)---*/
    printf("sending message to server...\n");
    send(sockfd, buffer, strlen(message.UTF8String), 0);

    return true;
}

@end
