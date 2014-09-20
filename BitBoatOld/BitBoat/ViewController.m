//
//  ViewController.m
//  BitBoat
//
//  Created by Ethan Gill on 9/19/14.
//  Copyright (c) 2014 sinjin. All rights reserved.
//

#import "ViewController.h"
//#import "FBShimmering/FBShimmeringView.h"
@import LocalAuthentication;

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIButton *payButton;

@end

@implementation ViewController
{

}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_statusImage setImage:[UIImage imageNamed:@"signal"]];
    [_payButton setEnabled:NO];
    [_payButton setTitle:@"Searching for Bill" forState:UIControlStateDisabled];
    [_companyName setHidden:YES];
    [_usdPrice setHidden:YES];
    [_btcPrice setHidden:YES];
    // Do any additional setup after loading the view, typically from a nib.
    
   
    
}
- (IBAction)payPressed:(id)sender {
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    NSString *myLocalizedReasonString = @"Authenticate to send BTC";
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:myLocalizedReasonString
                            reply:^(BOOL succes, NSError *error) {
                                
                                if (succes) {
                                    
                                    NSLog(@"User is authenticated successfully");
                                    [self updateStatusLabel];
                                } else {
                                    
                                    switch (error.code) {
                                        case LAErrorAuthenticationFailed:
                                            NSLog(@"Authentication Failed");
                                            break;
                                            
                                        case LAErrorUserCancel:
                                            NSLog(@"User pressed Cancel button");
                                            break;
                                            
                                        case LAErrorUserFallback:
                                            NSLog(@"User pressed \"Enter Password\"");
                                            break;
                                            
                                        default:
                                            NSLog(@"Touch ID is not configured");
                                            break;
                                    }
                                    
                                    NSLog(@"Authentication Fails");
                                }
                            }];
    } else {
        NSLog(@"Can not evaluate Touch ID");
        //The device the user is on does not have a Touch ID sensor. Ignore and don't require authorization for now
        [self updateStatusLabel];
    }
}
-(void) updateStatusLabel{
    dispatch_async(dispatch_get_main_queue(), ^{
                [_payButton setTitle:@"Transferring BTC" forState:UIControlStateDisabled];
                [_payButton setEnabled:NO];
                    });
}


- (void)transferBitcoin
{
    NSLog(@"Changing Now");
    [_payButton setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
