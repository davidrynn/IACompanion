//
//  HomeContentTableView.m
//  The Internet Archive Companion
//
//  Created by Hunter on 2/9/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "HomeContentTableView.h"
#import "ArchiveSearchDoc.h"
#import "HomeContentCell.h"
#import "ArchiveDetailedViewController.h"

@interface HomeContentTableView () {
    int start;
    NSString *sort;
    BOOL loading;

}

@end

@implementation HomeContentTableView


- (id) initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if(self){
        [self setDelegate:self];
        [self setDataSource:self];
        docs = [NSMutableArray new];
        start = 0;
        sort = @"publicdate+desc";
        loading = NO;
        _didTriggerLoadMore = NO;
        
        _service = [ArchiveDataService new];
        [_service setDelegate:self];

    }
    return  self;

}


- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self setDelegate:self];
        [self setDataSource:self];
        docs = [NSMutableArray new];
        start = 0;
        sort = @"publicdate+desc";
        loading = NO;
        _didTriggerLoadMore = NO;

        
        _service = [ArchiveDataService new];
        [_service setDelegate:self];
    
    }
    return self;
}




- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return docs.count;
    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}



- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    HomeContentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"homeContentCell"];
    ArchiveSearchDoc *doc = [docs objectAtIndex:indexPath.row];
    
    [cell.title setText:doc.title];
    [cell.aSyncImageView setAndLoadImageFromUrl:doc.headerImageUrl];
    [cell setDoc:doc];
    
    
    if([doc.rawDoc objectForKey:@"subject"]){
        
        NSMutableString * subs = [[NSMutableString alloc] init];
        for (NSObject * obj in [doc.rawDoc objectForKey:@"subject"])
        {
            if(![subs isEqualToString:@""]){
                [subs appendString:@", "];
            }
            [subs appendString:[obj description]];
        }
        [cell.subject setText:subs];
    } else {
        [cell.subject setText:@""];
    }
    
    
    
    return cell;
}






- (void) dataDidFinishLoadingWithDictionary:(NSDictionary *)results{
    loading = NO;

    if(!_didTriggerLoadMore){
        [docs removeAllObjects];
    }
    
    
    [docs addObjectsFromArray:[results objectForKey:@"documents"]];
    
    [self reloadData];
    
    if(!_didTriggerLoadMore){
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewRowAnimationTop animated:YES];
    }

    
    [_totalFound setText:[NSString stringWithFormat:@"%@ items found",  [results objectForKey:@"numFound"]]];

    
}






#pragma mark - scroll view delegates

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if(_scrollDelegate && [_scrollDelegate respondsToSelector:@selector(didScroll)]){
        [_scrollDelegate didScroll];
    }

}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(loading){
        [self loadMoreItems:nil];
    }
    
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView{
    // NSLog(@" offset: %f  width: %f ", scrollView.contentOffset.x + scrollView.frame.size.width, scrollView.contentSize.width);
    
    if(scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height + 100 && !loading){
        loading = YES;
    }
    
    
}


- (void)loadMoreItems:(id)sender {
    NSLog(@"-----> trigger loadmore");
    _didTriggerLoadMore = YES;
    start = start + docs.count;
    [_service loadMoreWithStart:[NSString stringWithFormat:@"%i", start]];
    
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
