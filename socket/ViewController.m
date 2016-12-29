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

@interface ViewController () <UITextFieldDelegate, ServerResponseDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel * ipAddress;
@property (weak, nonatomic) IBOutlet UITextField *incomingPortTextField;

@property (weak, nonatomic) IBOutlet UITextField *recipientIpAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *outcomingPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *message;
@property (nonatomic, strong) CommunicationExample * communication;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray * list;

@end

@implementation ViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    self.communication = [CommunicationExample new];
    self.communication.delegate = self;
    
    self.list = [NSMutableArray new];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    
    self.ipAddress.text = [ServerExample ipAddress];
    
    self.recipientIpAddressTextField.text = @"192.168.29.143";
    self.outcomingPortTextField.text = @"9009";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return true;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (IBAction)onRunClient:(id)sender {
    [self.communication sendMessage:self.message.text];
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//        //Background Thread
//        NSNumberFormatter * nf = [NSNumberFormatter new];
//        NSNumber * incomingPort = [nf numberFromString:self.incomingPortTextField.text];
//        NSNumber * outgoingPort = [nf numberFromString:self.outcomingPortTextField.text];
//        
//        NSString * str = [ServerExample runClient:self.recipientIpAddressTextField.text
//                                     outgoingPort:outgoingPort.integerValue
//                                responseIpAddress:self.ipAddress.text
//                                     responsePort:incomingPort.integerValue
//                                          message:self.message.text];
//        [self onResponse:str];
//        
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            //Run UI Updates
//        });
//    });
}

- (IBAction)onStartServer:(id)sender {
    NSNumberFormatter * nf = [NSNumberFormatter new];
    NSNumber * number = [nf numberFromString:self.outcomingPortTextField.text];
    [self.communication initNetworkCommunication:self.recipientIpAddressTextField.text port:number.unsignedIntValue];
//    [self.communication joinChat:[[UIDevice currentDevice] name]];
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//        //Background Thread
//        [ServerExample runServer:self port:number.integerValue];
//        
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            //Run UI Updates
//        });
//    });
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
