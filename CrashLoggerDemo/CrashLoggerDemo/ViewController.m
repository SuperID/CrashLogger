//
//  ViewController.m
//  CrashLoggerDemo
//
//  Created by YourtionGuo on 1/26/15.
//  Copyright (c) 2015 GYX. All rights reserved.
//

#import "ViewController.h"
#import "CrashLogger.h"

@interface ViewController ()
@property(strong, atomic)CrashLogger *crashHandle;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.crashHandle = [CrashLogger sharedInstance];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)add:(id)sender {
    [self.crashHandle setHandler];
}

- (IBAction)remove:(id)sender {
    [self.crashHandle remuseHandler];
}

- (IBAction)cash:(id)sender {
    [super delete:nil];
}

- (IBAction)get:(id)sender {
    NSLog(@"Log: %@",[self.crashHandle getCashLog]);
}

- (IBAction)delete:(id)sender {
    [self.crashHandle deleteCashLog];
}

@end
