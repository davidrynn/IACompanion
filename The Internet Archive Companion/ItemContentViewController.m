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
#import "CollectionDataHandlerAndHeaderView.h"
#import "StringUtils.h"



@interface ItemContentViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *mediaFiles;
@property (nonatomic, strong) NSMutableDictionary *organizedMediaFiles;
@property (nonatomic, weak) IBOutlet UITableView *mediaTable;
@property (nonatomic, weak) IBOutlet UIView *collectionHolderView;

@property (nonatomic, strong) NSURL *externalUrl;


@property (nonatomic, weak) IBOutlet CollectionDataHandlerAndHeaderView *collectionHandlerView;
@property (nonatomic, strong) IAJsonDataService *service;



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
    self.title = @"ITEM";
    [super viewDidLoad];

    self.navigationItem.title = @"";

	// Do any additional setup after loading the view.

    self.backButton = [[UIBarButtonItem alloc] initWithTitle:BACK style:UIBarButtonItemStylePlain target:self action:@selector(didPressBackButton)];
    [self.backButton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Iconochive-Regular" size:30.0]} forState:UIControlStateNormal];

    [self.navigationItem setLeftBarButtonItems:@[self.backButton]];


    mediaFiles = [NSMutableArray new];
    organizedMediaFiles = [NSMutableDictionary new];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:YES]];

    if ([self.mediaTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.mediaTable setSeparatorInset:UIEdgeInsetsZero];
    }
    
    NSLog(@"---->parent: %@", self.parentViewController.restorationIdentifier);
    if([self.parentViewController.restorationIdentifier isEqualToString:@"searchNav"])
    {

        UIBarButtonItem *favsToolBuuton = [[UIBarButtonItem alloc] initWithTitle:FAVORITE style:UIBarButtonItemStylePlain target:self action:@selector(didPressFavorites)];
        [favsToolBuuton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Iconochive-Regular" size:30.0]} forState:UIControlStateNormal];



        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:CLOSE style:UIBarButtonSystemItemCancel target:self action:@selector(closeSearch)];
        [closeItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Iconochive-Regular" size:20.0]} forState:UIControlStateNormal];
        
        [self.navigationItem setRightBarButtonItems:@[closeItem, self.mpBarButton, favsToolBuuton]];
        
        
        
    }




    [self.descriptionButton setSelected:YES];


    [self.itemWebView setOpaque:NO];
    self.itemWebView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self.itemWebView setBackgroundColor:[UIColor whiteColor]];

    self.itemWebView.alpha = 1.0;
    self.collectionHolderView.alpha = 0;
    self.mediaTable.alpha = 0;
    
    self.imageView.layer.cornerRadius = self.imageView.bounds.size.width / 2;
    self.imageView.layer.masksToBounds = YES;

    [self.service fetchData];


}

- (void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}
- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

}


- (void) setSearchDoc:(ArchiveSearchDoc *)searchDoc{
    _searchDoc = searchDoc;
    self.service = nil;
    self.service = [[IAJsonDataService alloc] initForMetadataDocsWithIdentifier:_searchDoc.identifier];
    [self.service setDelegate:self];

}


- (void) didPressMPButton {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenMediaPlayer" object:nil];
}

- (void)closeSearch
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchViewControllerClose" object:nil];
    [(UINavigationController*)self.parentViewController popViewControllerAnimated:NO];
}


- (void) didPressBackButton{
    [self.collectionHandlerView.service stopFetchingData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:NO]];
    [self.navigationController popViewControllerAnimated:YES];
}



- (IBAction)addFavorite:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddFavoriteNotification" object:self.searchDoc];
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
            
            if(self.detDoc.type != MediaTypeCollection) {
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
    }



    self.typeLabel.text = [MediaUtils iconStringFromMediaType:self.detDoc.type];
    [self.typeLabel setTextColor:[MediaUtils colorFromMediaType:self.detDoc.type]];

    if(self.detDoc.creator)
    {
        NSString *creator = self.detDoc.creator;
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", @"by", creator]];
        [attString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [@"by" length])];
        [attString addAttribute:NSForegroundColorAttributeName value:BUTTON_DEFAULT_SELECT_COLOR range:NSMakeRange(3, creator.length)];

        
        NSMutableAttributedString *selAtt = [[NSMutableAttributedString alloc] initWithAttributedString:attString];
        [selAtt addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(3, creator.length)];

        
        //[self.creatorButton.titleLabel setAttributedText:attString];
        
        [self.creatorButton setAttributedTitle:attString forState:UIControlStateNormal];
        [self.creatorButton setAttributedTitle:selAtt forState:UIControlStateHighlighted];

    }




    NSLog(@"------> imageUrl:%f", self.itemImageWidth);

    NSString *imgHtml = [NSString stringWithFormat:@"<img style='display:block; margin-left:auto; margin-right:auto; width:%fpx;' src='%@'/><br/>", self.itemImageWidth, self.itemImageUrl];


    if(self.detDoc.type == MediaTypeCollection)
    {
        imgHtml = @"";
        [self.typeLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setText:[NSString stringWithFormat:@"%@ Collection", self.detDoc.title]];
        [self.titleHolder setBackgroundColor:COLLECTION_BACKGROUND_COLOR];
       // [self.creatorButton setTitleColor:[] forState:<#(UIControlState)#>]];


        [self.collectionHandlerView setIdentifier:self.searchDoc.identifier];

        self.imageView.hidden = NO;
        self.typeLabel.hidden = YES;

        [self toggleViews:self.collectionButton];

    }
    else
    {
        NSString *date = [StringUtils displayDateFromArchiveDateString:self.detDoc.publicDate];
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", @"Archived", date]];
        [attString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [@"Archived" length])];
        [self.dateLabel setAttributedText:attString];

        self.imageView.hidden = YES;
        
        NSMutableArray *mItems = [NSMutableArray new];
        for (UIBarButtonItem *i in self.itemToolbar.items) {
            if(i != self.collectionBarButton)
            {
                [mItems addObject:i];
            }
        }
        [self.itemToolbar setItems:mItems];
    }

    NSString *html = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'/><style>img{max-width:%fpx !important;} a:link{color:#666; text-decoration:none;}</style></head><body style='margin-left:10px; margin-right:10px; background-color:#ffffff; color:#000; font-size:14px; font-family:\"Helvetica\"'>%@%@</body></html>", self.itemImageWidth, imgHtml, self.detDoc.details];
    

    NSURL *theBaseURL = [NSURL URLWithString:@"http://archive.org"];
    
    
    [self.itemWebView loadData:[html dataUsingEncoding:NSUTF8StringEncoding]
                             MIMEType:@"text/html"
                     textEncodingName:@"UTF-8"
                              baseURL:theBaseURL];
    

    [self.metaDataTable addMetadata:[self.detDoc.rawDoc objectForKey:@"metadata"]];
    
    

    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES];
    [mediaFiles addObjectsFromArray:[files sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]]];
    
    [self orgainizeMediaFiles:mediaFiles];

    if(organizedMediaFiles.count == 0)
    {
        self.folderButton.hidden = YES;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowLoadingIndicator" object:[NSNumber numberWithBool:NO]];

    
}


#pragma mark - toggle about and folders

- (IBAction)toggleViews:(id)sender
{
    self.mediaTable.hidden = sender != self.folderButton;
    self.itemWebView.hidden = sender != self.descriptionButton;
    self.collectionHolderView.hidden = sender != self.collectionButton;

    self.folderButton.selected = sender == self.folderButton;
    self.descriptionButton.selected = sender == self.descriptionButton;
    self.collectionButton.selected = sender == self.collectionButton;

    [UIView animateWithDuration:0.33 animations:^{



        self.itemWebView.alpha = sender == self.descriptionButton ? 1.0 : 0;
        self.collectionHolderView.alpha = sender == self.collectionButton ? 1.0 : 0;
        self.mediaTable.alpha = sender == self.folderButton ? 1.0 : 0;

    }];

}

#pragma mark - creator button
- (IBAction)didPressCreatorButton:(id)sender
{
//    NSString *encode = [self.detDoc.creator stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSCharacterSet *customAllowedSet =  [NSCharacterSet characterSetWithCharactersInString:@"=\"#%/&<>?@\\^`{|}"].invertedSet;
    NSString *sEncode = [self.detDoc.creator stringByAddingPercentEncodingWithAllowedCharacters:customAllowedSet];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchViewControllerCreator" object:[NSString stringWithFormat:@"creator:\"%@\"", sEncode]];
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
    
//    FileFormat64KbpsMP3 = 8,
//    FileFormat128KbpsMP3 = 12,
//    FileFormatMP3 = 13,
//    FileFormat96KbpsMP3 = 14,
//
    // REMOVING ALL AUDIO BESIDES VBR MP3
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormat128KbpsMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormat128KbpsMP3]];
    }
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormatMP3]];
    }
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormat96KbpsMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormat96KbpsMP3]];
    }
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormat64KbpsMP3]] != nil){
        [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormat64KbpsMP3]];
    }
    
    if(self.detDoc.type != MediaTypeTexts)
    {
        if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatDjVuTXT]] != nil){
            [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormatDjVuTXT]];
        }
        if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatTxt]] != nil){
            [organizedMediaFiles removeObjectForKey:[NSNumber numberWithInt:FileFormatTxt]];
        }
    }
    
    
    if([organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatVBRMP3]] != nil)
    {
        // Filtering out repeated titles in VBR List
        NSArray *vbrs = [organizedMediaFiles objectForKey:[NSNumber numberWithInt:FileFormatVBRMP3]];
        NSMutableSet* existingNames = [NSMutableSet set];
        NSMutableArray* filteredArray = [NSMutableArray array];
        for (ArchiveFile *file in vbrs) {
            if (![existingNames containsObject:file.title]) {
                [existingNames addObject:file.title];
                [filteredArray addObject:file];
            }
        }
        [organizedMediaFiles setObject:filteredArray forKey:[NSNumber numberWithInt:FileFormatVBRMP3]];
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
        } else if (aFile.format == FileFormatEPUB) {
            self.externalUrl = [NSURL URLWithString:aFile.url];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Web Page To Save EPUB Book" message:@"Do you want to open Safari?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alert show];

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
        NSString *format = [firstFile.file objectForKey:@"format"];

        headerCell.sectionHeaderLabel.text = format;
        [headerCell setTypeLabelIconFromFileTypeString:format];

        MediaType *type = [MediaUtils mediaTypeFromFileFormat:[MediaUtils formatFromString:format]];
        headerCell.sectionPlayAllButton.hidden = type == MediaTypeNone || type == MediaTypeTexts;
        [headerCell.sectionPlayAllButton setTag:section];
        [headerCell.sectionPlayAllButton addTarget:self action:@selector(playAll:) forControlEvents:UIControlEventTouchUpInside];
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
    


    UIButton *button = sender;
    NSArray *files = [organizedMediaFiles objectForKey:[[organizedMediaFiles allKeys]  objectAtIndex:button.tag]];
    for(ArchiveFile *aFile in files)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToPlayerListFileNotification" object:aFile];
    }

    [button.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    [button setTitle:[NSString stringWithFormat:@"%lu file%@ added to media player", (unsigned long)files.count, files.count > 1 ? @"s" : @""] forState:UIControlStateNormal];

    [self performSelector:@selector(changeTextBackForButton:) withObject:button afterDelay:3.0];

}


- (void)changeTextBackForButton:(UIButton *)button
{
    [button setTitle:@"" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont fontWithName:ICONOCHIVE size:20]];
    [button setTitle:PLUS forState:UIControlStateNormal];

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


- (IBAction)showWeb:(id)sender
{
    self.externalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Web Page" message:@"Do you want to view this web page with Safari?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if(buttonIndex == 1){
        [[UIApplication sharedApplication] openURL:self.externalUrl];

    }
}
- (NSString *)shareMessage{
    
    return [NSString stringWithFormat:@"From the Internet Archive: %@", [NSString stringWithFormat:@"http://archive.org/details/%@", self.detDoc.identifier]];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{

}

@end
