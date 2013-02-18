//
//  HomeCollectionViewController.m
//  IA
//
//  Created by Hunter on 2/18/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "HomeCollectionViewController.h"
#import "HomeContentCell.h"
#import "ArchiveSearchDoc.h"
#import "ArchiveDetailedViewController.h"

@interface HomeCollectionViewController ()

@end

@implementation HomeCollectionViewController

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
    
    [self.contentParentView.homeContentTableView.service getDocsWithCollectionIdentifier:_identifier];
    [self.contentParentView hideSplashView];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:@"collectionCellPush"]){
        
        HomeContentCell *cell = (HomeContentCell *)sender;
        ArchiveSearchDoc *doc = cell.doc;
        
        ArchiveDetailedViewController *detailViewController = [segue destinationViewController];
        [detailViewController setTitle:doc.title];
        [detailViewController setIdentifier:doc.identifier];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setIdentifier:(NSString *)identifier{
    _identifier = identifier;
}


@end
