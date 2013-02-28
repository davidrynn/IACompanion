//
//  ArchiveBookPageTextViewController.m
//  IA
//
//  Created by Hunter on 2/27/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "ArchiveBookPageTextViewController.h"
#import "ArchiveDataService.h"
@interface ArchiveBookPageTextViewController ()
{
    
    NSString *useUrl;
    int start;
    int end;
    int ReadPageBytesLength;

}
@end

@implementation ArchiveBookPageTextViewController


NSInteger const ReadPageBytesLengthiPhone = 400;
NSInteger const ReadPageBytesLengthiPhoneLong = 500;
NSInteger const ReadPageBytesLengthiPadPortrait = 2000;
NSInteger const ReadPageBytesLengthiPadLandscape = 1100;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

        /*
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {            
            if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){
                ReadPageBytesLength = ReadPageBytesLengthiPadLandscape;
            } else {
                ReadPageBytesLength = ReadPageBytesLengthiPadPortrait;

            }
        } else {
            ReadPageBytesLength = ReadPageBytesLengthiPhone;
        }  */
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSLog(@"-----> useUrl: %@  start:%i  end:%i", useUrl, start, end);

    
    [self adjustFontSizeForOrientation];

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //[self.bodyTextView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];

    
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{

    [self adjustFontSizeForOrientation];
}


- (void) loadPage{
    if(start > _file.size || start + ReadPageBytesLength > _file.size){
        [_bodyTextView setText:@"END OF FILE REACHED"];
    } else {
        [_bodyTextView setAndLoadViewFromUrl:useUrl withStartByte:start withLength:ReadPageBytesLength];
    }
    [_pageNumber setText:[NSString stringWithFormat:@"%i", _index + 1]];
    
    
    int paddingDenom = 10;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        paddingDenom = 8;
    }
    
    float padding = round(self.view.bounds.size.width / paddingDenom);
    [_bodyTextView setBounds:CGRectMake(padding, 40, self.view.bounds.size.width - padding, self.view.bounds.size.height - 40)];
}




- (void) adjustFontSizeForOrientation{
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){
        ReadPageBytesLength = ReadPageBytesLengthiPadLandscape;
    } else {
        ReadPageBytesLength = ReadPageBytesLengthiPadPortrait;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSLog(@"---> [[UIScreen mainScreen] bounds].size.height: %f", [[UIScreen mainScreen] bounds].size.height);
        if([[UIScreen mainScreen] bounds].size.height == 568){
            ReadPageBytesLength = ReadPageBytesLengthiPhoneLong;
        } else {
            ReadPageBytesLength = ReadPageBytesLengthiPhone;
        }
    }
    
    
    [self getPageWithFile:_file withIndex:_index];
    [self loadPage];
}


- (void) viewWillAppear:(BOOL)animated{
    
    //[self.bodyTextView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) getPageWithFile:(ArchiveFile *)file withIndex:(int)index{
    _index = index;
    start = 0;
    _file = file;
    if(file.size == 0){
        return;
    }
    //double indexes = file.size / 20;
    //int pages = round(indexes);
    
    
    
    if(index > 0){
        start = ReadPageBytesLength * _index;
    }

    NSLog(@"->ReadPageBytesLength: %i", ReadPageBytesLength);
        
        
    useUrl = [NSString stringWithFormat:@"http://%@%@/%@", _file.server, _file.directory, _file.name];
    
    
}




@end
