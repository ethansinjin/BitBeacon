//
//  AppDelegate.h
//  Bit Beacon
//
//  Created by Jonah Starling on 9/20/14.
//  Copyright (c) 2014 BitCat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (assign,nonatomic) int numberOfSales;
@property (assign,nonatomic) double totalProfit;
@property (assign,nonatomic) double lastSaleAmount;

@end

