//
//  CommunicationExample.m
//  socket
//
//  Created by Michael Roebuck on 12/28/16.
//  Copyright © 2016 Michael Roebuck. All rights reserved.
//

#import "CommunicationExample.h"

@interface CommunicationExample () <NSStreamDelegate> {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSString * response;
}

@end

@implementation CommunicationExample

- (void) initNetworkCommunication:(NSString *)ip port:(UInt32)port {
//    if(inputStream) {
//        [inputStream close];
//    }
//    if(outputStream) {
//        [outputStream close];
//    }
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, port, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
}

- (void)joinChat:(NSString *)deviceName {
    
    response  = [NSString stringWithFormat:@"iam:%@", deviceName];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

- (void)sendMessage:(NSString *)message {
    response  = [NSString stringWithFormat:@"msg:%@", message];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                long len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            if([self.delegate respondsToSelector:@selector(onResponse:)]) {
                                [self.delegate onResponse:output];
                            }
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"Stream Event Has Space Available");
//            if(response != nil) {
//                NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
//                [outputStream write:[data bytes] maxLength:[data length]];
//                response = nil;
//            }
        }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Connection closed");
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
            
        default:
            NSLog(@"Unknown Stream Event %lu", (unsigned long)streamEvent);
            break;
    }
}

@end
