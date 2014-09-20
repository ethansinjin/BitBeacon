//
//  ViewController.m
//  Bit Beacon
//
//  Created by Jonah Starling on 9/20/14.
//  Copyright (c) 2014 BitCat. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *statusIcon;

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

-(void) updateStatus{
    if (_priceField.text.length == 0)
    {
        NSLog (@"Field is empty");
    }
    else
    {
        NSLog (@"Field has some data");
        [_chargeButton setTitle:@"Charging..." forState:UIControlStateDisabled];
        [_chargeButton setEnabled:NO];
        [_statusIcon setImage:[UIImage imageNamed:@"signal"]];
    }
}

- (IBAction)buttonTapped:(UIButton *)sender {
    [self updateStatus];
}


@end
