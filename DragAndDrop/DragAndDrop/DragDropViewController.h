//
// Created on Mon, Feb. 18, 2013
// Authors:  Tom Kraljevic, Fernando Rodriguez
// Copyright (c) 2013 Luminix, Inc.
//
// This example is contributed freely to the public domain under the MIT license.
// http://opensource.org/licenses/MIT
//

#import <UIKit/UIKit.h>

@interface DragDropViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate, UIPopoverControllerDelegate>;
@property (weak, nonatomic) IBOutlet UITableView *tableA;
@property (weak, nonatomic) IBOutlet UITableView *tableB;

@end
