//
//  SettingsView.m
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SettingsView.h"
#import "DisplayCell.h"
#import "SourceCell.h"
#import "ArticleStorage.h"
#import "WebCacheService.h"
#import "NetworkService.h"
#import "Configuration.h"

#define kUIRowHeight			50.0
#define kUIRowLabelHeight		44.0
#define kUIProgressBarWidth		160.0
#define kUIProgressBarHeight	24.0
#define kSwitchButtonWidth		94.0
#define kSwitchButtonHeight		27.0

#define MAX_NETWORK_ERROR_TOR	10

extern int networkError;

@implementation SettingsView

@synthesize myTableView;
@synthesize switchCtl;

enum ControlTableSections
{
    kUIInformation_Section=0,
	kUISwitch_Section,
	kUITotalArticle_Section,
	kUITotalObject_Section,
	kUIDownloadedObject_Section
};

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)create_UIProgressView
{
	CGRect frame = CGRectMake(0.0, 0.0, kUIProgressBarWidth, kUIProgressBarHeight);
	progressBar = [[UIProgressView alloc] initWithFrame:frame];
	progressBar.progressViewStyle = UIProgressViewStyleDefault;
	progressBar.progress = 0.0;
}

- (void)create_UISwitch
{
	CGRect frame = CGRectMake(0.0, 0.0, kSwitchButtonWidth, kSwitchButtonHeight);
	switchCtl = [[UISwitch alloc] initWithFrame:frame];
	if (networkService.offlineMode == YES) {
		switchCtl.on = YES;
	}
	else {
		switchCtl.on = NO;
	}
	[switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	
	// in case the parent view draws with a custom color or gradient, use a transparent color
	switchCtl.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
	/*
	UINavigationItem *navItem = self.navigationItem;

	UIBarButtonItem *systemItem = [[[UIBarButtonItem alloc]
									initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
									target:self action:@selector(cleanCache:)] autorelease];
	navItem.rightBarButtonItem = systemItem;
	[systemItem release];
	*/
	
	storage = [ArticleStorage sharedArticleStorageInstance];
	cacheService = [WebCacheService sharedWebCacheServiceInstance];
	networkService = [NetworkService sharedNetworkServiceInstance];
	//[self create_UIProgressView];
	[self create_UISwitch];
	//formatter = [[NSDateFormatter alloc] init];
	//[formatter setDateFormat:@"%Y-%m-%d %H:%M:%S %Z"];
	//[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
}
/*
- (void)loadView {
	
	//self.view = myTableView;	
}
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title;
	switch (section)
	{
		case kUISwitch_Section:
		{
			title = nil;
			break;
		}
		case kUITotalArticle_Section:
		{
			title = nil; //@"Total Articles";
			break;
		}
		case kUITotalObject_Section:
		{
			title = nil; //@"Total Object";
			break;
		}
		case kUIDownloadedObject_Section:
		{
			title = nil; //@"Downloaded Object";
			break;
		}
		case kUIInformation_Section:
		{
			title = @"Verson (v.2.5.4):";
			break;
		}
	}
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSString *title;
	switch (section)
	{
		case kUISwitch_Section:
		{
			title = @"In the offline mode, BBCReader will not fetch articles from Internet. It will serve articles only from the cache.";;
			break;
		}
		case kUITotalArticle_Section:
		{
			title = @"The total number of articles available in offline.";
			break;
		}
		case kUITotalObject_Section:
		{
			title = @"Total objects include articles, pictures, and stylesheets.";
			break;
		}
		case kUIDownloadedObject_Section:
		{
			title = @"The objects that are already downloaded and available in offline.";
			break;
		}
		case kUIInformation_Section:
		{
			title = @"2010 Odina software.\n Maker of iGeoJournal.\n Map, camera, journal, and recorder,\n all in one place!\nVisit App Store for more information.";
			break;
		}
	}
	return title;
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result;
		
	switch ([indexPath row])
	{
		case 0:
		{
			result = kUIRowHeight;
			break;
		}
		case 1:
		{
			result = kUIRowLabelHeight;
			break;
		}
	}
	
	return result;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given row
//
- (UITableViewCell *)obtainTableCellForRow:(NSIndexPath*)indexPath
{
	UITableViewCell *cell = nil;
	NSInteger row = indexPath.row;
	
	if (indexPath.section == kUISwitch_Section) {
		if (row == 0)
			cell = [myTableView dequeueReusableCellWithIdentifier:kDisplaySwitchCell_ID];
		else if (row == 1)
			cell = [myTableView dequeueReusableCellWithIdentifier:kSourceCell_ID];
		
		
		if (cell == nil)
		{
			if (row == 0)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayDateCell_ID] autorelease];
			else if (row == 1)
				cell = [[[SourceCell alloc] initWithFrame:CGRectZero reuseIdentifier:kSourceCell_ID] autorelease];
		}		
	}
	else if (indexPath.section == kUIInformation_Section) {
		cell = [myTableView dequeueReusableCellWithIdentifier:kSourceCell_ID];
		if (cell == nil) 
			cell = [[[SourceCell alloc] initWithFrame:CGRectZero reuseIdentifier:kSourceCell_ID] autorelease];
	} 
	else {
		if (row == 0)
			cell = [myTableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
		else if (row == 1)
			cell = [myTableView dequeueReusableCellWithIdentifier:kSourceCell_ID];
	
	
		if (cell == nil)
		{
			if (row == 0)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
			else if (row == 1)
				cell = [[[SourceCell alloc] initWithFrame:CGRectZero reuseIdentifier:kSourceCell_ID] autorelease];
		}
	}
	
	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	UITableViewCell *cell = [self obtainTableCellForRow:indexPath];
	
	NSInteger nArticle = storage.numberOfArticles;
	NSInteger nImage = storage.numberOfImages;
	NSInteger nChannel = storage.numberOfChannel;
	NSInteger nCSS = cacheService.numberOfCSSs;
	NSInteger nDownload = networkService.numberOfDownloadedObjects;
	NSString *number = nil;
	
	TRACE("Status update: channel: %d, Article: %d, image: %d, CSS: %d, Download: %d\n", nChannel, nArticle, nImage, nCSS, nDownload);
	
	downloadProgress = (float) nDownload / (float) (nArticle+nImage+nChannel+nCSS);
	
	switch (indexPath.section)
	{
		case kUISwitch_Section:
		{
			if (row == 0)
			{
				// this cell hosts the UISwitch control
				((DisplayCell *)cell).nameLabel.text = @"Offline Mode:";
				((DisplayCell *)cell).view = switchCtl;
			}
			else
			{
				// this cell hosts the info on where to find the code
				((SourceCell *)cell).sourceLabel.text = @"In the offline mode, BBCReader will not fetch articles from Internet. It will serve articles only from the cache.";
			}
			break;
		}			
		case kUITotalArticle_Section:
		{
			if (row == 0)
			{
				((DisplayCell *)cell).nameLabel.text = @"Total Articles:";
				number = [[NSString alloc] initWithFormat:@"%d", nArticle];
				((DisplayCell *)cell).valueLabel.text = number;
				[number release];
			}
			else 
			{
				((SourceCell*)cell).sourceLabel.textColor = [UIColor grayColor];
				((SourceCell *)cell).sourceLabel.text = @"The total number of articles available in offline.";
			}
			break;
		}
		case kUITotalObject_Section:
		{
			if (row == 0)
			{
				// this cell hosts the UISlider control
				((DisplayCell *)cell).nameLabel.text = @"Total objects:";
				number = [[NSString alloc] initWithFormat:@"%d", nArticle+nImage+nCSS+nChannel];
				((DisplayCell *)cell).valueLabel.text = number;
				[number release];
				//((DisplayCell *)cell).view = sliderCtl;
			}
			else
			{
				// this cell hosts the info on where to find the code
				((SourceCell*)cell).sourceLabel.textColor = [UIColor grayColor];
				((SourceCell *)cell).sourceLabel.text = @"Total objects include articles, pictures, and stylesheets.";
			}
			break;
		}
			
		case kUIDownloadedObject_Section:
		{
			if (row == 0)
			{
				if (nDownload > (nArticle+nImage+nCSS+nChannel)) 
				{
					nDownload = (nArticle+nImage+nCSS+nChannel);
				}
				// this cell hosts the custom UISlider control
				((DisplayCell *)cell).nameLabel.text = @"Downloaded Objects:";
				number =[[NSString alloc] initWithFormat:@"%d", nDownload];
				
				((DisplayCell *)cell).valueLabel.text = number;
				[number release];
				//((DisplayCell *)cell).view = customSlider;
			}
			else
			{
				// this cell hosts the info on where to find the code
				((SourceCell*)cell).sourceLabel.textColor = [UIColor grayColor];
				((SourceCell *)cell).sourceLabel.text = @"The objects that are already downloaded and available in offline.";
			}
			break;
		}
		case kUIInformation_Section:
		{
            ((SourceCell*)cell).sourceLabel.text = @"Tap to checkout iGeoJournal";
            /*
			if (networkError > MAX_NETWORK_ERROR_TOR) {
				//((SourceCell*)cell).sourceLabel.textColor = [UIColor redColor];
				((SourceCell*)cell).sourceLabel.text = @"Due to the Internet condition or resuming from sleep, the downloading may have been interrupted. Please restart BBCReader to sync articles.";
			}
			else {
				if (downloadProgress > 0.9) {
					((SourceCell*)cell).sourceLabel.text = @"The current version downloads the minimum required objects to display a web page. You may see some broken links in offline mode.";
				}
				else {
					((SourceCell*)cell).sourceLabel.text = @"For best results, please do the first sync in 3G or WiFi.";
				}
				
			}
             */
			break;
		}
			
	}
	
	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)newIndexPath
{
    if (newIndexPath.row == kUIInformation_Section) {
        TRACE_HERE;
        NSString *url = @"itms-apps://itunes.com/apps/igeojournal";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        [tableView deselectRowAtIndexPath:newIndexPath animated:YES];
    }
}

- (IBAction)cleanCache:(id)sender
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Cache" message:@"You are about to clean cache contents. You will need to restart BBCReader to resync articles."
												   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
	
	/*
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Empty Cache: You are about to clear cache contents! You will need to restart BBCReader to sync articles."
													delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
													otherButtonTitles:@"Cancel", @"Empty Cache", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;//UIActionSheetStyleDefault;
	actionSheet.destructiveButtonIndex = 0;	// make the second button red (destructive)
	[actionSheet showInView:self.view];
	[actionSheet release];
	*/
	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	TRACE("%s, %d\n", __func__, buttonIndex);
	if (buttonIndex == 1) {
		[cacheService emptyCache];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restart BBCReader" message:@"You will need to restart BBCReader to sync articles."
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

- (void)switchAction:(id)sender
{
	TRACE("switchAction: value = %d", [sender isOn]);
	
	if ([sender isOn]) {
		// offline mode
		networkService.offlineMode = YES;
		[[Configuration sharedConfigurationInstance] setOfflineMode:YES];
	}
	else {
		networkService.offlineMode = NO;
		[[Configuration sharedConfigurationInstance] setOfflineMode:NO];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Offline mode has been disabled." message:@"You may need to press reload button to resync articles."
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

/*
- (void)viewDidLoad
{
	myTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.autoresizesSubviews = YES;
	[self.view addSubview:myTableView];
}
 */

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)viewDidUnload
{
	self.myTableView = nil;
	self.switchCtl = nil;
}

- (void)dealloc {
	//[progressBar release];
	[myTableView release];
	[switchCtl release];
	[super dealloc];
}


@end
