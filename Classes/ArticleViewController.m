//
//  ArticleViewController.m
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "ArticleViewController.h"
#import "ArticleStorage.h"
#import "TableCellView.h"
#import "NetworkService.h"
#import "SectionSetting.h"
#import "WebCacheService.h"
#import "Configuration.h"


#define NO_IMAGE_AVAIABLE	@"none"
#define DEFAULT_IMAGE		@"default"

@implementation ArticleViewController

@synthesize theTableView;
@synthesize viewMode;
//@synthesize theNavigationBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		defaultBBCLogo = [UIImage imageNamed:@"new_logo.png"];
		viewMode = MAIN_ARTICLE_MODE;
		/*
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																							   target:nil
																							   action:nil] autorelease];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																								target:nil
																								action:nil] autorelease];
		*/
		statusView.backgroundColor = [UIColor blackColor];
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */


- (void)viewDidLoad 
{
	self.view.autoresizesSubviews = NO;
	isThisOtherView = NO;
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	//self.title = [storage getActiveArticleTitle];
	if ([storage articleNaviationMode] == ARTICLE_OTHER_NAV_MODE) {
		/*
		UINavigationItem *navItem = self.navigationItem;
	
		UIBarButtonItem *systemItem = [[[UIBarButtonItem alloc]
										initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
										target:self action:@selector(setToSegmentControl:)] autorelease];
	
		navItem.rightBarButtonItem = systemItem;
		*/
		isThisOtherView = YES;
	}
	/*
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	if (service.networkNotWorking == YES) {
		message = [[[UILabel alloc] initWithFrame:CGRectMake(80, TABLE_HEIGHT/2-20.0, 190.0, 30.0)] autorelease]; 
		message.font = [UIFont systemFontOfSize:13.0]; 
		message.textColor = [UIColor blackColor]; 
		message.lineBreakMode = UILineBreakModeWordWrap; 
		message.numberOfLines = 2;
		message.text = @"Download failed and the offline contents are not available.";
		[theTableView addSubview:message];
		[message release];
		
	}
	else {
		
		CGRect frame = CGRectMake((TABLE_WIDTH)/2.0-40, TABLE_HEIGHT/2.0-20, 25.0, 25.0);
		progressView = [[UIActivityIndicatorView alloc] initWithFrame:frame];
		progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray; //UIActivityIndicatorViewStyleWhiteLarge;
		progressView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
										 UIViewAutoresizingFlexibleRightMargin |
										 UIViewAutoresizingFlexibleTopMargin |
										 UIViewAutoresizingFlexibleBottomMargin);
		[theTableView addSubview:progressView];
		
		message = [[[UILabel alloc] initWithFrame:CGRectMake((TABLE_WIDTH)/2.0-10, TABLE_HEIGHT/2-20, 190.0, 30.0)] autorelease]; 
		message.font = [UIFont systemFontOfSize:13.0]; 
		message.textColor = [UIColor blackColor]; 
		message.lineBreakMode = UILineBreakModeWordWrap; 
		message.numberOfLines = 2;
		message.text = @"Loading ...";
		[theTableView addSubview:message];
		
		[progressView startAnimating];
	}
	*/
	statusUpdate.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
	statusUpdate.textColor = [UIColor whiteColor]; 
	statusUpdate.lineBreakMode = UILineBreakModeWordWrap; 
	[self updateDownloadStatus];
	//statusUpdate.text = @"Downloading ...";
	activityIndicator.hidesWhenStopped = YES;
	//[activityIndicator startAnimating];
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	if (config.lastUpdatedDate != nil) {
		/* for detailed information on Unicode date format patterns, see:
		 <http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns> */
		lastUpdate.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
		lastUpdate.textColor = [UIColor whiteColor];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEE, MMM d hh:mm aaa"];
		NSString *formattedDate = [[NSString alloc] initWithFormat:[formatter stringFromDate:config.lastUpdatedDate]];
		lastUpdate.text = formattedDate;
		[formattedDate release];
		[formatter release];
	}
	
	[infoButton addTarget:self action:@selector(openSectionSetting:) forControlEvents:UIControlEventTouchUpInside];
	
	//[progressView release];
	//[message release];
}

- (void)updateDownloadStatus
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	WebCacheService *cacheService = [WebCacheService sharedWebCacheServiceInstance];
	NetworkService *networkService = [NetworkService sharedNetworkServiceInstance];
	
	@synchronized (self) {
		NSInteger nArticle = storage.numberOfArticles;
		NSInteger nImage = storage.numberOfImages;
		NSInteger nChannel = storage.numberOfChannel;
		NSInteger nCSS = cacheService.numberOfCSSs;
		NSInteger nDownload = networkService.numberOfDownloadedObjects;
		
		
		TRACE("Status update: channel: %d, Article: %d, image: %d, CSS: %d, Download: %d\n", nChannel, nArticle, nImage, nCSS, nDownload);
		
		if (nDownload > (nArticle+nImage+nChannel+nCSS)) {
			nDownload = (nArticle+nImage+nChannel+nCSS);
		}
		float downloadProgress = ((float) nDownload / (float) (nArticle+nImage+nChannel+nCSS)) * 100.0;
		
		//message = [[[UILabel alloc] initWithFrame:CGRectMake((tableFrame.size.width-180)/2.0, tableFrame.size.height/2.0-30, 190.0, 30.0)] autorelease]; 
		if (downloadProgress < 0.0) {
			downloadProgress = 0.0;
		}
		
		NSString *update = nil; 
		if (networkService.offlineMode == YES) {
			update = [[NSString alloc] initWithFormat:@"Offline: %d articles available.", nArticle];
			statusUpdate.text = update;
			[update release];
			
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		} 
		else if ((nDownload >= (nArticle+nImage+nChannel+nCSS)) ||
				 (networkService.activeThreadCount <= 0)) {
			if ([activityIndicator isAnimating] == YES) 
				[activityIndicator stopAnimating];
			update = [[NSString alloc] initWithFormat:@"Updated: %d articles available.", nArticle];
			statusUpdate.text = update;
			[update release];
			
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		}
		else {
			if ([activityIndicator isAnimating] == NO) {
				[activityIndicator startAnimating];
			}
			update = [[NSString alloc] initWithFormat:@"Downloading... : %.0f%%", downloadProgress];
			statusUpdate.text = update;
			[update release];
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		}
		
		Configuration *config = [Configuration sharedConfigurationInstance];
		//if ([lastUpdateDate compare:config.lastUpdatedDate] != NSOrderedSame) {
		if (config.lastUpdatedDate != nil) {
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"EEE, MMM d hh:mm aaa"];
			NSString *formattedDate = [[NSString alloc] initWithFormat:[formatter stringFromDate:config.lastUpdatedDate]];
			lastUpdate.text = formattedDate;
			[formattedDate release];
			[formatter release];
			//lastUpdateDate = config.lastUpdatedDate;		
		}
		//}
	}
}

- (void)openSectionSetting:(id)sender
{
	SectionSetting* section = [[SectionSetting alloc] initWithNibName:@"SectionSetting" bundle:nil];
	//[sevc setDelegate:self];
	
	UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:section];
	[section release];
	[self.navigationController presentModalViewController:nc animated:YES];
	[nc release];
	
}

/*
 * TODO: 
 *	1. Get XML feed from network service
 *	2. Whenever there is an update, should be able to display the new entries.
 */
//- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
//}

//- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
//}

// TableViewDataSource methods


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* identity = @"NTYCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	UILabel *title = nil;
	UILabel *description = nil;
	NSString *imageLink = nil;
	UIImage *image = nil;
	TableCellView *imageRect = nil;
	BOOL dontDoAnything = NO;
	BOOL reusableCell = NO;
	BOOL isAvailable = NO;
	BOOL useOther = (viewMode==MAIN_ARTICLE_MODE?NO:YES);
	
	ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	
	if (cell == nil) {
		TRACE("---> cell is created.\n");
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
	}
	else {
		reusableCell = YES;
	}
	
	imageRect = (TableCellView*)[cell.contentView viewWithTag:MREADER_IMG_TAG];
	if (imageRect == nil) {
		imageRect = [[[TableCellView alloc] initWithFrame:CGRectMake(IMG_RECT_X, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT)] autorelease];
		imageRect.tag = MREADER_IMG_TAG;
		[imageRect setImageLink:NO_IMAGE_AVAIABLE];
	}
	
	title = (UILabel*)[cell.contentView viewWithTag:MREADER_TITLE_TAG];
	if (title == nil) {
		title = [[[UILabel alloc] initWithFrame:CGRectMake(TITLE_RECT_X, TITLE_RECT_Y, TITLE_RECT_WIDTH, TITLE_RECT_HEIGHT)] autorelease]; 
		title.tag = MREADER_TITLE_TAG;
		title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];//[UIFont systemFontOfSize:14.0]; 
		title.textColor = [UIColor blackColor]; 
		title.lineBreakMode = UILineBreakModeWordWrap; 
		title.numberOfLines = 2;
		//title.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	
	
	description = (UILabel*)[cell.contentView viewWithTag:MREADER_DESCRIPTION_TAG];
	if (description == nil) {
		description = [[[UILabel alloc] initWithFrame:CGRectMake(DESC_RECT_X, DESC_RECT_Y, DESC_RECT_WIDTH, DESC_RECT_HEIGHT)] autorelease];
		description.tag = MREADER_DESCRIPTION_TAG;
		description.font = [UIFont fontWithName:@"HelveticaNeue" size:12];//[UIFont systemFontOfSize:12.0];
		description.textColor = [UIColor grayColor];
		description.lineBreakMode = UILineBreakModeTailTruncation;
		description.numberOfLines = 4;
		//description.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	
	imageLink = [storage getArticleImageAtIndex:indexPath useOther:useOther available:(BOOL*)&isAvailable];
	if (imageLink != nil) {		
		// Image link is available.
		//			[storage addImage:image];
		
		
		if ([imageRect compareImageLink:imageLink] == NO) {
			// new image link is set
			if (([imageRect compareImageLink:DEFAULT_IMAGE] == NO) && (imageRect.image != nil)) 
				[imageRect.image release];
			image = [[UIImage alloc] initWithContentsOfFile:imageLink];
			if (image == nil) {
				NSLog(@"%s, %@ is null.", __func__, imageLink);
			}
			imageRect.image = image;
			[imageRect setImageLink:imageLink];
			if (reusableCell == NO)
				[cell.contentView addSubview:imageRect];
		}
		else {
			dontDoAnything = YES;
		}
	
		
		//[image release];
		//[imageLink release];
	}
	else if ([imageRect compareImageLink:DEFAULT_IMAGE] == NO) {
		// The current image in the cell is not default image.
		// Change to default image.
		if (imageRect.image != nil)
			[imageRect.image release];
		imageRect.image = defaultBBCLogo;
		[imageRect setImageLink:DEFAULT_IMAGE];
		if (reusableCell == NO)
			[cell.contentView addSubview:imageRect];
	}
	else {
		dontDoAnything = YES;
	}
	
	/* TODO: doesn't really tell the content is available or not. Better way to do it. 
	if (isAvailable == YES) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton; 
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}*/

	//if (dontDoAnything == YES) {
	//	NSLog(@"tableView: %@, section: %d, row: %d, image: %@", title.text, indexPath.section, indexPath.row, imageLink);
	//}
	
	NSString *text = [storage getArticleTextAtIndex:indexPath useOther:useOther];
	if ((title.text == nil) || 
		([title.text compare:text] != NSOrderedSame)) {
		title.text = text;
		//NSLog(@"tableView text: %@", title.text);
		if (reusableCell == NO)
			[cell.contentView addSubview:title];
	}
	
	NSString *descriptionText = [storage getArticleDescriptionAtIndex:indexPath useOther:useOther];
	if ((description.text == nil) || 
		([description.text compare:descriptionText] != NSOrderedSame)) {
		description.text = descriptionText;
		if (reusableCell == NO)
			[cell.contentView addSubview:description];
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self updateDownloadStatus];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	return [storage countSection];
}

- (void)setToSegmentControl:(id)sender
{
	// open a dialog with two custom buttons
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Set to main article view"
															 delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
													otherButtonTitles:@"to Segment 1", @"to Segment 2", @"to Segment 3", @"Cancel", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;//UIActionSheetStyleDefault;
	actionSheet.destructiveButtonIndex = 0;	// make the second button red (destructive)
	[actionSheet showInView:self.view];
	[actionSheet release];
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[[ArticleStorage sharedArticleStorageInstance] setOtherToSemgentWithIndex:buttonIndex];
}

/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
}
 */

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section 
{
	ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	int c = [storage countArticleInSection:section useOther:(viewMode==MAIN_ARTICLE_MODE?NO:YES)];
	//NSLog(@"%s, %d", __func__, c);
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	if (message == nil && c == 0 && service.networkNotWorking == YES) {
		message = [[[UILabel alloc] initWithFrame:CGRectMake(80, TABLE_HEIGHT/2-20.0, 190.0, 30.0)] autorelease]; 
		message.font = [UIFont systemFontOfSize:13.0]; 
		message.textColor = [UIColor blackColor]; 
		message.lineBreakMode = UILineBreakModeWordWrap; 
		message.numberOfLines = 2;
		message.text = @"Download failed and the offline contents are not available.";
		[theTableView addSubview:message];
		
	}
	else if (progressView == nil && c == 0) {
		CGRect frame = CGRectMake((TABLE_WIDTH)/2.0-40, TABLE_HEIGHT/2.0-20, 25.0, 25.0);
		progressView = [[UIActivityIndicatorView alloc] initWithFrame:frame];
		progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray; //UIActivityIndicatorViewStyleWhiteLarge;
		progressView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
										 UIViewAutoresizingFlexibleRightMargin |
										 UIViewAutoresizingFlexibleTopMargin |
										 UIViewAutoresizingFlexibleBottomMargin);
		[theTableView addSubview:progressView];
		
		message = [[[UILabel alloc] initWithFrame:CGRectMake((TABLE_WIDTH)/2.0-10, TABLE_HEIGHT/2-20, 190.0, 30.0)] autorelease]; 
		message.font = [UIFont systemFontOfSize:13.0]; 
		message.textColor = [UIColor blackColor]; 
		message.lineBreakMode = UILineBreakModeWordWrap; 
		message.numberOfLines = 2;
		message.text = @"Loading ...";
		[theTableView addSubview:message];
		
		[progressView startAnimating];
		
	}
	else if (c > 0) {
		if (progressView != nil) {
			[progressView stopAnimating];
			[progressView removeFromSuperview];	
		}
		if (message != nil) {
			[message removeFromSuperview];
		}
		
		progressView = nil;
		message = nil;
		if (isThisOtherView == YES) {
			
			// update segment control index
			[storage updateOtherIndexToActive];
		}
		
	}
	
	return c;
}

- (void)showNetworkError
{
	if (progressView) {
		[progressView stopAnimating];
		[progressView removeFromSuperview];
	}
	[message removeFromSuperview];

	message = [[[UILabel alloc] initWithFrame:CGRectMake(80, TABLE_HEIGHT/2-20.0, 190.0, 30.0)] autorelease]; 
	message.font = [UIFont systemFontOfSize:13.0]; 
	message.textColor = [UIColor blackColor]; 
	message.lineBreakMode = UILineBreakModeWordWrap; 
	message.numberOfLines = 2;
	message.text = @"Download failed and the offline contents are not available.";
	[theTableView addSubview:message];
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	//NSLog(@"%s, section: %d", __func__, section);
	ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	return [storage getTitleInSection:section useOther:(viewMode==MAIN_ARTICLE_MODE?NO:YES)];
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath*)newIndexPath
{ 
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	
	if ([service.protectFeed tryLock] == YES) {
		// Open web view
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(openWebViewAtIndex:) withObject:(id)newIndexPath waitUntilDone:YES];
	}
	else {
		TRACE("%s, can't get lock.\n", __func__);
	}
	[service.protectFeed unlock];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	//NSLog(@"%s", __func__);
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[progressView release];
	[message release];
	[super dealloc];
}


@end
