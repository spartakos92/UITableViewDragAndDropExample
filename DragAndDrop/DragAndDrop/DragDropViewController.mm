//
// Created on Mon, Feb. 18, 2013
// Authors:  Tom Kraljevic, Fernando Rodriguez
// Copyright (c) 2013 Luminix, Inc.
//
// This example is contributed freely to the public domain under the MIT license.
// http://opensource.org/licenses/MIT
//

#import "DragDropViewController.h"
#import "UserDetailViewController.h"
#include <deque>
#include <vector>
#include <string>
#include <map>

template <class M, class K>
inline bool mapContains (const M &m, const K &k) {
    if (m.find (k) != m.end()) {
        return true;
    }
    
    return false;
}

class SObjectData {
public:
    void setField (const std::string &key, const std::string &value) {
        _map[key] = value;
    }
    
    void getField (const std::string &key, std::string &value) const {
        if (! mapContains(_map, key)) {
            return;
        }
        
        value = _map[key];
    }

    void safeGetField (const std::string &key, std::string &value) const {
        assert (mapContains(_map, key));
        value = _map[key];
    }

private:
    mutable std::map<std::string, std::string> _map;
};

typedef std::deque<SObjectData> CellList_t;

@implementation DragDropViewController
{
    CellList_t _listA;
    CellList_t _listB;
    std::map<std::string,std::string> _idMap;
    
    UIView *_tmpView;
    
    bool _dragging;
    bool _panning;
    UITableView *_fromTable;
    UITableView *_toTable;
    CellList_t *_fromList;
    CellList_t *_toList;
    int _draggedIdx;
    CGRect _beginDraggedRect;
    
    UIPopoverController *_infoPopover;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)hackInitListEntry:(CellList_t &)list
                       Id:(const std::string &)Id
                FirstName:(const std::string &)FirstName
                 LastName:(const std::string &)LastName
                    Title:(const std::string &)Title
                ManagerId:(const std::string &)ManagerId
{
    std::string name = FirstName;
    if (name.size()) {
        name += " ";
    }
    name += LastName;
    
    SObjectData tmp;
    list.push_back (tmp);
    SObjectData &data = list.back();
    data.setField("Id", Id);
    data.setField("FirstName", FirstName);
    data.setField("LastName", LastName);
    data.setField("Name", name);
    data.setField("Title", Title);
    data.setField("ManagerId", ManagerId);
    
    _idMap[Id] = name;
}

- (void)hackInitLists
{
    [self hackInitListEntry:_listA Id:"100" FirstName:"Alice" LastName:"Adams" Title:"Sales Manager" ManagerId:"200"];
    [self hackInitListEntry:_listA Id:"101" FirstName:"Bob" LastName:"Boone" Title:"Sales Ops" ManagerId:"200"];
    [self hackInitListEntry:_listA Id:"200" FirstName:"Charlie" LastName:"Cooper" Title:"Sales Director, West Region" ManagerId:""];
    [self hackInitListEntry:_listA Id:"300" FirstName:"Don" LastName:"Drysdale" Title:"Engineer" ManagerId:""];
    [self hackInitListEntry:_listA Id:"302" FirstName:"Eddie" LastName:"Edwards" Title:"Sales Rep, West" ManagerId:"100"];
    [self hackInitListEntry:_listA Id:"303" FirstName:"Lakshminarayanan" LastName:"Venkatasubramanian" Title:"Sales Rep, West" ManagerId:"100"];

    [self hackInitListEntry:_listB Id:"301" FirstName:"MyFirstName" LastName:"MyLastName" Title:"Sales Rep, West" ManagerId:"100"];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    UISwipeGestureRecognizer *gr1a = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeA:)];
    gr1a.direction = UISwipeGestureRecognizerDirectionRight;
    gr1a.numberOfTouchesRequired = 1;
    [self.tableA addGestureRecognizer:gr1a];

    UISwipeGestureRecognizer *gr1aa = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeA:)];
    gr1aa.direction = UISwipeGestureRecognizerDirectionLeft;
    gr1aa.numberOfTouchesRequired = 1;
    [self.tableA addGestureRecognizer:gr1aa];

    UILongPressGestureRecognizer *gr2a = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLPA:)];
    [self.tableA addGestureRecognizer:gr2a];
    
    UIPanGestureRecognizer *gr3a = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanA:)];
    gr3a.delegate = self;
    [self.tableA addGestureRecognizer:gr3a];
    

    
    
    UISwipeGestureRecognizer *gr1bb = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeB:)];
    gr1bb.direction = UISwipeGestureRecognizerDirectionRight;
    gr1bb.numberOfTouchesRequired = 1;
    [self.tableB addGestureRecognizer:gr1bb];
    
    UISwipeGestureRecognizer *gr1b = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeB:)];
    gr1b.direction = UISwipeGestureRecognizerDirectionLeft;
    gr1b.numberOfTouchesRequired = 1;
    [self.tableB addGestureRecognizer:gr1b];
    
    UILongPressGestureRecognizer *gr2b = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLPB:)];
    [self.tableB addGestureRecognizer:gr2b];
    
    UIPanGestureRecognizer *gr3b = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanB:)];
    gr3b.delegate = self;
    [self.tableB addGestureRecognizer:gr3b];

    
    
    
    [self hackInitLists];
    
    _tmpView = nil;
    _dragging = false;
    _panning = false;
    _draggedIdx = -1;
    _fromTable = nil;
    _toTable = nil;
    _fromList = nil;
    _toList = nil;
    _infoPopover = nil;
}

- (void)viewDidUnload {
    [self setTableA:nil];
    [self setTableB:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CellList_t &list = (tableView == _tableA) ? _listA : _listB;
    int s = list.size();
    return s;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CellList_t &list = (tableView == _tableA) ? _listA : _listB;
    NSString *identifier = (tableView == _tableA) ? @"listA" : @"listB";
    int i = indexPath.row;
    UITableViewCell *cell;
    if (i < list.size()) {
        // This could be some custom table cell class if appropriate
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            // Any other attributes of the cell that will never change for type \"A\" cells.
        }

        std::string Name;
        list[i].safeGetField("Name", Name);
        UILabel *label = (UILabel*) [cell viewWithTag:1];
        [label setText:[NSString stringWithUTF8String:Name.c_str()]];
    }
    else {
        cell = [[UITableViewCell alloc] init];
        [cell setUserInteractionEnabled:NO];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_infoPopover isPopoverVisible]) {
        [_infoPopover dismissPopoverAnimated:NO];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    const CellList_t &list = (tableView == _tableA) ? _listA : _listB;
    if (indexPath.row >= list.size()) {
        return;
    }
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UserDetailViewController *vc = (UserDetailViewController*) [sb instantiateViewControllerWithIdentifier:@"UserDetailViewController"];
    
    std::string Name;
    std::string Title;
    std::string ManagerId;
    std::string Manager;
    const SObjectData &data = list[indexPath.row];
    data.safeGetField("Name", Name);
    data.getField("Title", Title);
    data.getField("ManagerId", ManagerId);
    Manager = _idMap[ManagerId];
    _infoPopover = [[UIPopoverController alloc] initWithContentViewController:vc];
    _infoPopover.delegate = self;
    [vc.nameLabel setText:[NSString stringWithUTF8String:Name.c_str()]];
    [vc.titleLabel setText:[NSString stringWithUTF8String:Title.c_str()]];
    [vc.managerLabel setText:[NSString stringWithUTF8String:Manager.c_str()]];

    CGRect rowRect = [tableView rectForRowAtIndexPath:indexPath];
    CGRect popoverRect = [tableView convertRect:rowRect toView:self.view];
    
    [_infoPopover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

static const char *
state2str (UIGestureRecognizerState state)
{
    switch (state) {
    case UIGestureRecognizerStatePossible:  return "Possible";
    case UIGestureRecognizerStateBegan:     return "Began";
    case UIGestureRecognizerStateChanged:   return "Changed";
    case UIGestureRecognizerStateEnded:     return "Ended";
    case UIGestureRecognizerStateCancelled: return "Cancelled";
    case UIGestureRecognizerStateFailed:    return "Failed";
    default:                                return "Unknown";
    }
}

- (void)cancelDragging
{
    if (! _dragging) {
        return;
    }
    
    [_tmpView removeFromSuperview];
    _tmpView = nil;
    
    _dragging = false;
    _panning = false;
    _draggedIdx = -1;
    _fromTable = nil;
    _toTable = nil;
    _fromList = nil;
    _toList = nil;
}

-(void)startDragging:(int)draggedIdx draggedName:(NSString*)draggedName location:(CGPoint)location
{
    _dragging = true;
    _draggedIdx = draggedIdx;
    _tmpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [_tmpView setBackgroundColor:[UIColor blackColor]];
    UILabel *label = [[UILabel alloc] initWithFrame:_tmpView.bounds];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = draggedName;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor lightGrayColor];
    [_tmpView addSubview:label];

    [[self view] addSubview:_tmpView];
    _tmpView.center = location;
    _beginDraggedRect = _tmpView.frame;
}

- (void)handleSwipe:(UIGestureRecognizer *)gestureRecognizer
              table:(UITableView *)table
               list:(CellList_t &)list
{
    UIGestureRecognizerState state = [gestureRecognizer state];
    
    CGPoint loc = [gestureRecognizer locationInView:table];
    NSLog(@"SWIPE (%9s) (%f,%f)", state2str(state), loc.x, loc.y);
    
    NSIndexPath *indexPath = [table indexPathForRowAtPoint:loc];
    UITableViewCell* cell = [table cellForRowAtIndexPath:indexPath];
    
    if (! cell) {
        return;
    }
    
    if (indexPath.row >= list.size()) {
        NSLog (@"Not in any row");
        return;
    }
    
    std::string Name;
    list[indexPath.row].safeGetField("Name", Name);
    NSLog(@"SWIPE Cell row(%d) value(%s)", indexPath.row, Name.c_str());
    
    if (state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (_dragging) {
        [self cancelDragging];
    }
    
    [self startDragging:indexPath.row
            draggedName:[NSString stringWithUTF8String:Name.c_str()]
               location:[gestureRecognizer locationInView:self.view]];
}

- (void)handleSwipeA:(UIGestureRecognizer *)gestureRecognizer {
    _fromTable = _tableA;
    _toTable = _tableB;
    _fromList = &_listA;
    _toList = &_listB;
    NSLog(@"SWIPE A -----");
    [self handleSwipe:gestureRecognizer table:_fromTable list:*_fromList];
}

- (void)handleSwipeB:(UIGestureRecognizer *)gestureRecognizer {
    _fromTable = _tableB;
    _toTable = _tableA;
    _fromList = &_listB;
    _toList = &_listA;
    NSLog(@"SWIPE B -----");
    [self handleSwipe:gestureRecognizer table:_fromTable list:*_fromList];
}

- (void)handleLP:(UIGestureRecognizer *)gestureRecognizer
           table:(UITableView *)table
            list:(CellList_t &)list
{
    UIGestureRecognizerState state = [gestureRecognizer state];
    
    CGPoint loc = [gestureRecognizer locationInView:table];
    NSLog(@"LP (%9s) (%f,%f)", state2str(state), loc.x, loc.y);
    
    NSIndexPath *indexPath = [table indexPathForRowAtPoint:loc];
    UITableViewCell* cell = [table cellForRowAtIndexPath:indexPath];
    
    if (! cell) {
        return;
    }
    
    if (indexPath.row >= list.size()) {
        NSLog (@"Not in any row");
        return;
    }
    
    std::string Name;
    list[indexPath.row].safeGetField("Name", Name);
    NSLog(@"LP Cell row(%d) value(%s)", indexPath.row, Name.c_str());
    
    if (state == UIGestureRecognizerStateBegan) {
        if (_dragging) {
            [self cancelDragging];
        }

        [self startDragging:indexPath.row
                draggedName:[NSString stringWithUTF8String:Name.c_str()]
                   location:[gestureRecognizer locationInView:self.view]];
    }
    else if (state == UIGestureRecognizerStateEnded) {
        if (_dragging) {
            if (! _panning) {
                [self cancelDragging];
            }
        }
    }
}

- (void)handleLPA:(UIGestureRecognizer *)gestureRecognizer {
    _fromTable = _tableA;
    _toTable = _tableB;
    _fromList = &_listA;
    _toList = &_listB;
    NSLog(@"LP A -----");
   [self handleLP:gestureRecognizer table:_fromTable list:*_fromList];
}

- (void)handleLPB:(UIGestureRecognizer *)gestureRecognizer {
    _fromTable = _tableB;
    _toTable = _tableA;
    _fromList = &_listB;
    _toList = &_listA;
    NSLog(@"LP B -----");
    [self handleLP:gestureRecognizer table:_fromTable list:*_fromList];
}

- (void)handlePan:(UIGestureRecognizer *)gestureRecognizer {
    UIGestureRecognizerState state = [gestureRecognizer state];
    
    CGPoint loc = [gestureRecognizer locationInView:self.view];
    NSLog(@"PAN (%9s) (%f,%f)", state2str(state), loc.x, loc.y);

    if (state == UIGestureRecognizerStateBegan) {
        _panning = true;
    }
    
    if (state == UIGestureRecognizerStateEnded) {
        if (_dragging) {
            CGPoint locationInView;
            locationInView = [gestureRecognizer locationInView:_fromTable];
            if (CGRectContainsPoint(_fromTable.bounds, locationInView)) {
                NSLog(@"Dropped in FROM table");
                goto cancel;
            }
            
            locationInView = [gestureRecognizer locationInView:_toTable];
            if (CGRectContainsPoint(_toTable.bounds, locationInView)) {
                NSLog(@"Dropped in TO table");
                
                SObjectData &data = (*_fromList)[_draggedIdx];
                _toList->push_back(data);
                _fromList->erase(_fromList->begin() + _draggedIdx);

                NSArray *arr;
                arr = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:_draggedIdx inSection:0]];
                [_fromTable deleteRowsAtIndexPaths:arr withRowAnimation:UITableViewRowAnimationAutomatic];
                
                arr = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:_toList->size()-1 inSection:0]];
                [_toTable insertRowsAtIndexPaths:arr withRowAnimation:UITableViewRowAnimationAutomatic];
                
                [self cancelDragging];
 
                return;
            }
            
        cancel:
            [UIView animateWithDuration:0.5
                             animations:^()
             {
                 _tmpView.frame = _beginDraggedRect;
             }
                             completion:^(BOOL finished)
             {
                 [self cancelDragging];
             }];
            return;
        }
    }
    
    if (_dragging) {
        _tmpView.center = loc;
    }
}

- (void)handlePanA:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"PAN A -----");
    [self handlePan:gestureRecognizer];
}

- (void)handlePanB:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"PAN B -----");
    [self handlePan:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return TRUE;
}

#pragma mark - UIPopoverController Delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _infoPopover = nil;
}

@end
