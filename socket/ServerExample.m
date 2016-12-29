//
//  ServerExample.m
//  socket
//
//  Created by Michael Roebuck on 12/28/16.
//  Copyright © 2016 Michael Roebuck. All rights reserved.
//

#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>

#include <string.h>

#import "ServerExample.h"

@implementation ServerExample

+ (NSString *)ipAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

+ (NSString *) runClient:(NSString *)outgoingIpAddress
      outgoingPort:(NSInteger)outgoingPort
 responseIpAddress:(NSString *)responseIpAddress
      responsePort:(NSInteger)responsePort
           message: (NSString *)message {
    
    struct in_addr ipv4addr;
    int sockfd;
    ssize_t n;
    struct sockaddr_in serv_addr;
    struct hostent *server;
    char buffer[4096];
    
    /* Create a socket point */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    
    if (sockfd < 0) {
        perror("ERROR opening socket\n");
        return nil;
    }
    
    inet_pton(AF_INET, outgoingIpAddress.UTF8String, &ipv4addr);
    server = gethostbyaddr(&ipv4addr, sizeof ipv4addr, AF_INET);
    
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host\n");
        return nil;
    }
    else {
        printf("Host name: %s\n", server->h_name);
    }
    
    //set all the socket structures with null values
    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    
    //copies nbyte bytes from string s1 to the string s2
    bcopy((char *)server->h_addr, (char *)&serv_addr.sin_addr.s_addr, server->h_length);
    serv_addr.sin_port = htons(outgoingPort);
    
    /* Now connect to the server */
    if (connect(sockfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
        perror("ERROR connecting\n");
        return nil;
    }
    
    /* Send message to the server */
    NSMutableString * ms = [NSMutableString new];
//        [ms appendString:@"HEAD / HTTP/1.1\r\n"];
//        [ms appendString:@"Host: www.example.com\r\n"];
//        [ms appendString:@"Connection: Close\r\n\r\n"];
//        [ms appendString:@"Accept: application/json"];
//        [ms appendString:@"Content-Type : application/json"];
//        [ms appendString:@"Content-Length: 0"];
//        [ms appendString:@"HEAD / HTTP/1.1\r\n"];
//        [ms appendString:@"Connection: Close\r\n\r\n"];
        [ms appendFormat:@"{\"Host Name\" : \"%@\", \"Port\" : \"%ld\", \"message\" : \"%@\"}", responseIpAddress, responsePort, message];
    n = write(sockfd, ms.UTF8String, strlen(ms.UTF8String));
    
    if (n < 0) {
        perror("ERROR writing to socket\n");
        return nil;
    }
    
    /* Now read server response */
    bzero(buffer,4095);
    n = read(sockfd, buffer, 4095);
    
    if (n < 0) {
        perror("ERROR reading from socket\n");
        return nil;
    }
    
    printf("Response: %s\n",buffer);
    
    close(sockfd);
    
    return [NSString stringWithFormat:@"%s", buffer];
}

+ (void) runServer:(id<ServerResponseDelegate>)delegate port:(NSInteger)port {
    int newsockfd, sockfd;
    socklen_t clilen;
    struct sockaddr_in serv_addr, cli_addr;
    int pid;
    
    /* First call to socket() function */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    
    if (sockfd == 0) {
        perror("ERROR opening socket");
        return;
    }
    
    /* Initialize socket structure */
    bzero((char *) &serv_addr, sizeof(serv_addr));
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(port);
    
    /* Now bind the host address using bind() call.*/
    if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) != 0) {
        perror("ERROR on binding");
        return;
    }
    
    /* Now start listening for the clients, here
     * process will go in sleep mode and will wait
     * for the incoming connection
     */
    
    listen(sockfd,5);
    clilen = sizeof(cli_addr);
    
    while (1) {
        newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
        
        if (newsockfd < 0) {
            perror("ERROR on accept");
            return;
        }
        
        /* Create child process */
        pid = fork();
        
        if (pid < 0) {
            perror("ERROR on fork");
            return;
        }
        
        else {
//        if (pid == 0) {
            /* This is the client process */
            close(sockfd);
            [self processInput:delegate sock:newsockfd];
            close(newsockfd);
            return;
        }
//        else {
//            close(newsockfd);
//        }
        
    }
}

+ (void) processInput:(id<ServerResponseDelegate>)delegate sock:(int)sock {
    size_t n;
    char buffer[4096];
    bzero(buffer,4096);
    n = read(sock,buffer,4095);
    
    if (n == 0) {
        perror("ERROR reading from socket");
        return;
    }
    
    if([delegate respondsToSelector:@selector(onResponse:)]) {
        [delegate onResponse:[NSString stringWithFormat:@"%s", buffer]];
    }
    
    printf("Here is the message: %s\n",buffer);
    n = write(sock,"I got your message",18);
    
    if (n == 0) {
        perror("ERROR writing to socket");
        return;
    }
}

@end
