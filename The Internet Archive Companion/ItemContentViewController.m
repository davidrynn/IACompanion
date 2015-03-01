//
//  ItemContentViewController.m
//  IA
//
//  Created by Hunter on 6/30/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import "ItemContentViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ArchiveFile.h"
#import "MediaFileCell.h"
#import "MediaFileHeaderCell.h"
#import "MediaImageViewController.h"
#import "ArchivePageViewController.h"
#import <Social/Social.h>
#import "MediaUtils.h"
#import "FontMapping.h"


@interface ItemContentViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *mediaFiles;
@property (nonatomic, strong) NSMutableDictionary *organizedMediaFiles;
@property (nonatomic, weak) IBOutlet UITableView *mediaTable;







@end

@implementation ItemContentViewController
@synthesize mediaFiles, organizedMediaFiles, mediaTable;

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
    
    [self.navigationItem setLeftBarButtonItems:@[self.backButton, self.listButton, self.mpBarButton]];
    [self.service fetchData];
    
    
//    self.archiveDescription = [[UIWebView alloc] initWithFrame:CGRectZero];
//    self.archiveDescription.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
//    [self.archiveDescription setBackgroundColor:[UIColor clearColor]];
//    [self.archiveDescription setOpaque:NO];
//    [self.archiveDescription setDelegate:self];

    mediaFiles = [NSMutableArray new];
    organizedMediaFiles = [NSMutableDictionary new];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:YES]];

    if ([self.mediaTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.mediaTable setSeparatorInset:UIEdgeInsetsZero];
    }



    [self.descriptionButton setSelected:YES];


    [self.itemWebView setOpaque:NO];
    self.itemWebView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self.itemWebView setBackgroundColor:[UIColor whiteColor]];
    
}

- (void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}
- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    


    
}

#pragma mark - Results

- (void) dataDidBecomeAvailableForService:(IADataService *)service{
    
    //ArchiveDetailDoc *doc = ((IAJsonDataService *)service).rawResults
    assert([[((IAJsonDataService *)service).rawResults objectForKey:@"documents"] objectAtIndex:0] != nil);
    self.detDoc = [[((IAJsonDataService *)service).rawResults objectForKey:@"documents"] objectAtIndex:0];
    
    self.titleLabel.text = self.detDoc.title;
    if(self.detDoc.archiveImage){
        [self.imageView setArchiveImage:self.detDoc.archiveImage];
        self.itemImageUrl = self.detDoc.archiveImage.urlPath;
        self.itemImageWidth = 300.0f;

    }


    BOOL gotAnImage = NO;
    NSMutableArray *files = [NSMutableArray new];
    for(ArchiveFile *file in self.detDoc.files){
        if(file.format != FileFormatOther){
            [files addObject:file];
            if((file.format == FileFormatJPEG || file.format == FileFormatPNG) && ![[file.file objectForKey:@"source"] isEqualToString: @"derivative"]) {
                if(gotAnImage == NO)
                {
                    ArchiveImage *image = [[ArchiveImage alloc] initWithUrlPath:file.url];
                    [self.imageView setArchiveImage:image];
                    gotAnImage = YES;
                    self.itemImageUrl = file.url;
                    self.itemImageWidth = self.itemWebView.bounds.size.width > 320 ? ceil(self.itemWebView.bounds.size.width * 0.75)  : 300;
                }
            }

        }
    }



    self.typeLabel.text = [MediaUtils iconStringFromMediaType:self.detDoc.type];
    [self.typeLabel setTextColor:[MediaUtils colorFromMediaType:self.detDoc.type]];





    if(self.detDoc.creator)
    {
        [self.byLabel setText:[NSString stringWithFormat:@"by %@", self.detDoc.creator]];
    }

    NSLog(@"------> imageUrl:%f", self.itemImageWidth);

    NSString *html = [NSString stringWithFormat:@"<html><head><style>a:link{color:#666; text-decoration:none;}</style></head><body style='background-color:#ffffff; color:#000; font-size:14px; font-family:\"Helvetica\"'><img style='display:block; margin-left:auto; margin-right:auto; width:%fpx;' src='%@'/><br/>%@</body></html>", self.itemImageWidth == 0 ? self.itemWebView.bounds.size.width - 20 : self.itemImageWidth, self.itemImageUrl, self.detDoc.details];
    

    NSURL *theBaseURL = [NSURL URLWithString:@"http://archive.org"];
    
    
    [self.itemWebView loadData:[html dataUsingEncoding:NSUTF8StringEncoding]
                             MIMEType:@"text/html"
                     textEncodingName:@"UTF-8"
                              baseURL:theBaseURL];
    

    [self.metaDataTable addMetadata:[self.detDoc.rawDoc objectForKey:@"metadata"]];
    
    

    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES];
    [mediaFiles addObjectsFromArray:[files sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]]];
    
    [self orgainizeMediaFiles:mediaFiles];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:NO]];

    
}


#pragma mark - toggle about and folders

- (IBAction)toggleViews:(id)sender
{
    self.mediaTable.hidden = !self.mediaTable.hidden;
    self.itemWebView.hidden = !self.itemWebView.hidden;

    self.folderButton.selected = !self.folderButton.selected;
    self.descriptionButton.selected = !self.descriptionButton.selected;

}

#pragma mark -

- (void) orgainizeMediaFiles:(NSMutableArray *)files{
    for(ArchiveFile *f in files){
        if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:f.format]] != nil){

            if(f.format == FileFormatPNG && [[f.file objectForKey:@"source"] isEqualToString: @"derivative"] )
            { } else {
            [[organizedMediaFiles objectForKey:[NSNumber numberWithInt:f.format]] addObject:f];
            }

        } else {

            if(f.format == FileFormatPNG && [[f.file objectForKey:@"source"] isEqualToString: @"derivative"] )
            { } else {
                NSMutableArray *filesForFormat = [NSMutableArray new];
                [filesForFormat addObject:f];
                [organizedMediaFiles setObject:filesForFormat forKey:[NSNumber numberWithInt:f.format]];            }
        }
    }
    
    [mediaTable reloadData];
    
}

#pragma mark - Table Stuff
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(organizedMediaFiles.count == 0){
        return @"";
    }
    
    ArchiveFile *firstFile;
    firstFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:section]] objectAtIndex:0];
    return [firstFile.file objectForKey:@"format"];
  
} 

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MediaFileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaFileCell"];
    
    if(organizedMediaFiles.count > 0){
        ArchiveFile *aFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        cell.fileTitle.text = aFile.title;
        cell.fileFormat.text = [aFile.file objectForKey:@"format"];
        cell.durationLabel.text = [aFile.file objectForKey:@"duration"];
        cell.fileName.text = aFile.name;
        
    }
    
    
    return cell;

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(organizedMediaFiles.count > 0){
        ArchiveFile *aFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if(aFile.format == FileFormatJPEG || aFile.format == FileFormatGIF || aFile.format == FileFormatPNG) {
            MediaImageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"mediaImageViewController"];
            [vc setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            ArchiveImage *image = [[ArchiveImage alloc] initWithUrlPath:aFile.url];
            [vc setImage:image];
            [self presentViewController:vc animated:YES completion:nil];
        } else if (aFile.format == FileFormatDjVuTXT || aFile.format == FileFormatProcessedJP2ZIP || aFile.format == FileFormatTxt) {
            ArchivePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"archivePageViewController"];
            [pageViewController setIdentifier:self.searchDoc.identifier];
            [pageViewController setBookFile:aFile];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenBookViewer" object:pageViewController];


        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToPlayerListFileAndPlayNotification" object:aFile];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenMediaPlayer" object:nil];
        }
    }
}


- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    MediaFileHeaderCell *headerCell = [tableView dequeueReusableCellWithIdentifier:@"mediaFileHeaderCell"];

    if(organizedMediaFiles.count > 0){
        ArchiveFile *firstFile;
        firstFile = [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:section]] objectAtIndex:0];
        headerCell.sectionHeaderLabel.text = [firstFile.file objectForKey:@"format"];
        [headerCell setTypeLabelIconFromFileTypeString:[firstFile.file objectForKey:@"format"]];
    }
    return headerCell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return organizedMediaFiles.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(organizedMediaFiles.count == 0){
        return 0;
    }

    return [[organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:section]] count];
}


#pragma mark -


- (IBAction)playAll:(id)sender
{
    
    for(ArchiveFile *aFile in mediaFiles) {
        if(aFile.format == FileFormatJPEG || aFile.format == FileFormatGIF || aFile.format == FileFormatPNG)
        {
            
        }
        else if (aFile.format == FileFormatDjVuTXT || aFile.format == FileFormatProcessedJP2ZIP || aFile.format == FileFormatTxt)
        {
            
        } else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToPlayerListFileNotification" object:aFile];
        }
    }

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenMediaPlayer" object:nil];
}








- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0 || buttonIndex == 1) {
        
        NSString *serviceType = buttonIndex == 0 ? SLServiceTypeFacebook : SLServiceTypeTwitter;
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        
        NSString *archiveUrl = [NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier];
        [controller addURL:[NSURL URLWithString:archiveUrl]];
  //      [controller setInitialText:[NSString stringWithFormat:@"Internet Archive - %@", self.detDoc.title]];
        

        [self presentViewController:controller animated:YES completion:nil];
        
    }  else if (buttonIndex == 2) {
        
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            [mailViewController setSubject:self.detDoc.title];
            [mailViewController setMessageBody:[self shareMessage] isHTML:YES];
            [self presentViewController:mailViewController animated:YES completion:nil];
        } else {
            [self displayUnableToSendEmailMessage];
        }
    }
    
}

- (void)displayEmailSentMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Sent"
                                                    message:@"Your message was successfully sent."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:( MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            //  NSLog(@"Message Canceled");
            break;
        case MFMailComposeResultSaved:
            //  NSLog(@"Message Saved");
            break;
        case MFMailComposeResultSent:
            [self displayEmailSentMessage];
            break;
        case MFMailComposeResultFailed:
            [self displayUnableToSendEmailMessage];
            break;
        default:
            //  NSLog(@"Message Not Sent");
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)displayUnableToSendEmailMessage {
    NSString *errorMessage = @"The device is unable to send email in its current state.";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Send Email"
                                                    message:errorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
- (NSString *)shareMessage{
    
    return [NSString stringWithFormat:@"From the Internet Archive: %@", [NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
