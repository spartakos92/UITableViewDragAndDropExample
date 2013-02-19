//
// Created on Mon, Feb. 18, 2013
// Authors:  Tom Kraljevic, Fernando Rodriguez
// Copyright (c) 2013 Luminix, Inc.
//
// This example is contributed freely to the public domain under the MIT license.
// http://opensource.org/licenses/MIT
//

#import "UserDetailViewController.h"

@interface UserDetailViewController ()

@end

@implementation UserDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setNameLabel:nil];
    [self setTitleLabel:nil];
    [self setManagerLabel:nil];
    [super viewDidUnload];
}
@end
