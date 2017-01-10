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
#import "CommunicationExample.h"
#import "SocketClient.h"

#define kClientType             2

@interface ViewController () <UITextFieldDelegate, ServerResponseDelegate, SocketClientDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel * ipAddress;
@property (weak, nonatomic) IBOutlet UITextField *incomingPortTextField;

@property (weak, nonatomic) IBOutlet UITextField *recipientIpAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *outcomingPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *message;
@property (nonatomic, strong) CommunicationExample * communication;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray * list;

@property (nonatomic, strong) SocketClient * socketClient;

@end

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    self.communication = [CommunicationExample new];
    self.communication.delegate = self;
    
    self.list = [NSMutableArray new];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    
    self.ipAddress.text = [ServerExample ipAddress];
    
    self.recipientIpAddressTextField.text = @"192.168.200.86"; //@"192.168.29.143";
    self.outcomingPortTextField.text = @"5020"; //@"9009";
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    
    //Allow users to close the window when we touch outside of either textfield
    if(!([touch.view isEqual:self.incomingPortTextField]
         || [touch.view isEqual:self.recipientIpAddressTextField]
         || [touch.view isEqual:self.outcomingPortTextField]
         || [touch.view isEqual:self.message])) {
        if([self.incomingPortTextField isFirstResponder]) {
            [self.incomingPortTextField resignFirstResponder];
        }
        else if([self.recipientIpAddressTextField isFirstResponder]) {
            [self.recipientIpAddressTextField resignFirstResponder];
        }
        else if([self.outcomingPortTextField isFirstResponder]) {
            [self.outcomingPortTextField resignFirstResponder];
        }
        else if([self.message isFirstResponder]) {
            [self.message resignFirstResponder];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return true;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (IBAction)onStartServer:(id)sender {
    
    NSNumberFormatter * nf = [NSNumberFormatter new];
    NSNumber * number = [nf numberFromString:self.outcomingPortTextField.text];
    
    if(kClientType == 1) {
        [self startSocketClient:self.recipientIpAddressTextField.text port:number.unsignedIntegerValue];
    }
    else if(kClientType == 2) {
        [self startCommunicationClient:self.recipientIpAddressTextField.text port:number.unsignedIntegerValue];
    }
    else if(kClientType == 3) {
        [self startServerExample:self.recipientIpAddressTextField.text port:number.unsignedIntegerValue];
    }
}


- (IBAction)onRunClient:(id)sender {
    
    if(kClientType == 1) {
        [self writeToSocketClient:self.message.text];
    }
    else if(kClientType == 2) {
        [self writeToCommunicationClient:self.message.text];
    }
    else if(kClientType == 3) {
        [self writeToServerExample:self.message.text];
    }
}

- (void) startSocketClient:(NSString *)ip port:(NSUInteger)port {
    
    if(self.socketClient) {
        [self.socketClient stop];
        self.socketClient = nil;
    }
    
    self.socketClient = [SocketClient instanceWithDelegate:self];
    if([self.socketClient start:ip
                    port_number:port]) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self.socketClient read];
        });
    }
}

- (void) startCommunicationClient:(NSString *)ip port:(UInt32)port {
    
    [self.communication initNetworkCommunication:ip port:port];
    [self.communication joinChat:[[UIDevice currentDevice] name]];
}

- (void) startServerExample:(NSString *)ip port:(UInt32)port {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        [ServerExample runServer:self port:port];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
        });
    });
}

- (void) writeToSocketClient:(NSString *)message {
    if(self.socketClient) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self.socketClient write:message];
        });
    }
}

- (void) writeToCommunicationClient:(NSString *)message {
    [self.communication sendMessage:self.message.text];
}

- (void) writeToServerExample:(NSString *)message {
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

- (IBAction)onClear:(id)sender {
    [self.list removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^(void){
        //Run UI Updates
        [self.tableView reloadData];
    });
}

- (void) onResponse:(NSString *)response {
    
    if(response) {
        NSCharacterSet *charc=[NSCharacterSet newlineCharacterSet];
        [self.list addObject:[response stringByTrimmingCharactersInSet:charc]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [self.tableView reloadData];
        });
    }
}

- (void) onServerResponse:(NSString *)response {
    
    if(response) {
        NSCharacterSet *charc=[NSCharacterSet newlineCharacterSet];
        [self.list addObject:[response stringByTrimmingCharactersInSet:charc]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [self.tableView reloadData];
        });
    }
}

- (void) onSocketClosed {
    
    if(self.socketClient) {
        self.socketClient = nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    NSString * str = self.list[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld: %@", indexPath.row, str];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
