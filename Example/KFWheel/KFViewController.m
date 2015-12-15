//
//  KFViewController.m
//  KFWheel
//
//  Created by kwabford on 12/13/2015.
//  Copyright (c) 2015 kwabford. All rights reserved.
//

#import "KFViewController.h"
#import <KFWheel/KFWheel.h>

@interface KFViewController ()

@property (strong, nonatomic) IBOutlet UILabel *wheelLabel;
@property (strong, nonatomic) IBOutlet KFWheel *wheel;

@end

@implementation KFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onValueChanged:(KFWheel *)sender {
    self.wheelLabel.text = [NSString stringWithFormat:@"Wheel Value:\n%.3f", sender.value];
}

- (IBAction)testSetWheelValue:(UIButton *)sender {
    self.wheel.value = 10.5;
}
@end
