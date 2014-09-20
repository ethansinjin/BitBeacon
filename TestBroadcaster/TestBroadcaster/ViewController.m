//
//  ViewController.m
//  TestBroadcaster
//
//  Created by Ethan Gill on 9/20/14.
//  Copyright (c) 2014 sinjin. All rights reserved.
//

#import "ViewController.h"
#import "JGBeacon.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)broadcast:(id)sender {
    NSString *address = [_field1 text];
    NSString *amt = [_field2 text];
    
    JGBeacon *beacon = [[JGBeacon alloc]init];
    [beacon s]
}

@end
