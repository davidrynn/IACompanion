//
//  HomeCombinedViewController.m
//  The Internet Archive Companion
//
//  Created by Hunter on 2/9/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "HomeCombinedViewController.h"
#import "ArchiveSearchDoc.h"
#import "ArchiveDetailedViewController.h"
#import "HomeContentCell.h"

@interface HomeCombinedViewController () {

}




@end

@implementation HomeCombinedViewController

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



    
    
    [self doOrientationLayout:self.interfaceOrientation];

    
    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if([[segue identifier] isEqualToString:@"homeCellPush"]){
    
        HomeContentCell *cell = (HomeContentCell *)sender;
        ArchiveSearchDoc *doc = cell.doc;
        
        ArchiveDetailedViewController *detailViewController = [segue destinationViewController];
        [detailViewController setTitle:doc.title];
        [detailViewController setIdentifier:doc.identifier];
    }


}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    [self.contentScrollView.homeContentView.homeContentTableView deselectRowAtIndexPath:self.contentScrollView.homeContentView.homeContentTableView.indexPathForSelectedRow animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self doOrientationLayout:toInterfaceOrientation];

}




- (void) doOrientationLayout:(UIInterfaceOrientation)toInterfaceOrientation{
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        [self.contentScrollView setContentSize:CGSizeMake(1024, 10)];
        
    } else {
        [self.contentScrollView setContentSize:CGSizeMake(1024, 10)];
        
    }
    
    [self.contentScrollView.homeNavTableView reloadData];
    [self.contentScrollView.homeContentView.homeContentTableView reloadData];
    
}
 




@end
