//
//  ArchiveBookPageTextViewController.h
//  IA
//
//  Created by Hunter on 2/27/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArchiveFile.h"
#import "AsyncTextView.h"

@interface ArchiveBookPageTextViewController : UIViewController


- (void) getPageWithFile:(ArchiveFile *)file withIndex:(int)index;

@property (nonatomic, weak) IBOutlet AsyncTextView *bodyTextView;
@property (nonatomic, weak) IBOutlet UILabel *pageNumber;
@property (nonatomic) int index;
@property (nonatomic, retain) ArchiveFile *file;

@end
