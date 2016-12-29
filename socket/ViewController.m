//
//  ViewController.m
//  socket
//
//  Created by Michael Roebuck on 12/16/16.
//  Copyright © 2016 Michael Roebuck. All rights reserved.
//

#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>

#include <netdb.h>
#include <netinet/in.h>

#include <string.h>

#import "ViewController.h"
#import "ServerExample.h"

@interface ViewController () <UITextFieldDelegate, ServerResponseDelegate>

@property (weak, nonatomic) IBOutlet UILabel * ipAddress;
@property (weak, nonatomic) IBOutlet UITextField *incomingPortTextField;

@property (weak, nonatomic) IBOutlet UITextField *recipientIpAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *outcomingPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *message;

@property (weak, nonatomic) IBOutlet UITextView *receivedMessages;

@end

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    
    self.receivedMessages.userInteractionEnabled = false;
    
    weakSelf.ipAddress.text = [ServerExample ipAddress];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return true;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (IBAction)onRunClient:(id)sender {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        NSNumberFormatter * nf = [NSNumberFormatter new];
        NSNumber * incomingPort = [nf numberFromString:self.incomingPortTextField.text];
        NSNumber * outgoingPort = [nf numberFromString:self.outcomingPortTextField.text];
        
        NSString * str = [ServerExample runClient:self.recipientIpAddressTextField.text
                                     outgoingPort:outgoingPort.integerValue
                                responseIpAddress:self.ipAddress.text
                                     responsePort:incomingPort.integerValue
                                          message:self.message.text];
        [self onResponse:str];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
        });
    });
}

- (IBAction)onStartServer:(id)sender {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        NSNumberFormatter * nf = [NSNumberFormatter new];
        NSNumber * number = [nf numberFromString:self.incomingPortTextField.text];
        [ServerExample runServer:self port:number.integerValue];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
        });
    });
}

- (void) onResponse:(NSString *)response {
    
    if(response) {
        NSMutableString * ms = [NSMutableString new];
        
        if(self.receivedMessages.text.length > 0) {
            [ms appendString:self.receivedMessages.text];
        }
        [ms appendFormat:@"%@\n", response];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            self.receivedMessages.text = ms.copy;
        });
    }
}

@end
