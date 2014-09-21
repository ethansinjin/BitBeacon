//
//  ViewController.m
//  Bit Beacon
//
//  Created by Jonah Starling on 9/20/14.
//  Copyright (c) 2014 BitCat. All rights reserved.
//

#import "ViewController.h"
#import "NewSaleViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIView *summaryView;

@property (strong, nonatomic) IBOutlet UILabel *numberOfSalesL;
@property (strong, nonatomic) IBOutlet UILabel *totalProfitL;
@property (strong, nonatomic) IBOutlet UILabel *lastSaleAmountL;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_summaryView.layer setCornerRadius:50.0f];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    [_lastSaleAmountL setText:[NSString stringWithFormat:@"%.2f",appDelegate.lastSaleAmount]];
    [_totalProfitL setText:[NSString stringWithFormat:@"%.2f",appDelegate.totalProfit]];
    [_numberOfSalesL setText:[NSString stringWithFormat:@"%d",appDelegate.numberOfSales]];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    [_lastSaleAmountL setText:[NSString stringWithFormat:@"%.2f",appDelegate.lastSaleAmount]];
    [_totalProfitL setText:[NSString stringWithFormat:@"%.2f",appDelegate.totalProfit]];
    [_numberOfSalesL setText:[NSString stringWithFormat:@"%d",appDelegate.numberOfSales]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
