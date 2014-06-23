//
//  FTGViewController.m
//  FTGNotificationControllerDemo
//
//  Created by Khoa Pham on 6/19/14.
//  Copyright (c) 2014 Fantageek. All rights reserved.
//

#import "FTGViewController.h"
#import "FTGNotificationController.h"

@interface FTGViewController ()

@property (nonatomic, strong) FTGNotificationController *notificationController;

@end

@implementation FTGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.notificationController = [FTGNotificationController controllerWithObserver:self];

}

- (IBAction)observeMemoryWarningNotification:(id)sender
{
    UIApplication *application = [UIApplication sharedApplication];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:application];

}
- (IBAction)unobserveMemoryWarningNotificationButtonAction:(id)sender
{
    UIApplication *application = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:application];

}

- (IBAction)unobserverAllButtonAction:(id)sender
{
    [self.notificationController unobserveAll];

}

- (void)handleNotification:(id)note
{
    NSLog(@"");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
