#include "MReader_Defs.h"

#import "WebViewHistoryController.h"
#import "ArticleStorage.h"
#import "TableCellView.h"
#import "NetworkService.h"
#import "Configuration.h"
#import "WebLink.h"
#import "WebViewController.h"

#define NO_IMAGE_AVAIABLE	@"none"
#define DEFAULT_IMAGE		@"default"

@implementation WebViewHistoryController

@synthesize theTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		defaultBBCLogo = [UIImage imageNamed:@"new_logo.png"];
		self.theTableView.delegate = self;
		self.theTableView.dataSource = self;
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
	//ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	//self.title = [storage getActiveArticleTitle];
	
	configuration = [Configuration sharedConfigurationInstance];
	
	self.navigationItem.title = @"History";
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearHistory:)];

	self.navigationItem.rightBarButtonItem = item;
	[item release];
	
}

- (void)clearHistory:(id)sender
{
	[configuration clearHistory];
	[theTableView reloadData];
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
	int rect_x = RECT_START_MARGIN;
	int rect_y = 0.0;
	BOOL shouldAddImageCell = NO;
	BOOL reusableCell = NO;
	
	if (cell == nil) {
		TRACE("---> cell is created.\n");
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
	}
	else {
		reusableCell = YES;
	}
	
	WebLink *link = [configuration.history objectAtIndex:indexPath.row];
	imageLink = link.imageLink;
	
	title = (UILabel*)[cell.contentView viewWithTag:MREADER_TITLE_TAG];
	rect_y = TITLE_RECT_WIDTH;
	if (imageLink == nil) {
		rect_y += IMG_RECT_WIDTH;
	}
	
	if (title == nil) {
		title = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, TITLE_RECT_Y, rect_y, TITLE_RECT_HEIGHT)] autorelease]; 
		title.tag = MREADER_TITLE_TAG;
		title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15]; //[UIFont systemFontOfSize:15.0]; 
		title.textColor = [UIColor blackColor]; 
		title.lineBreakMode = UILineBreakModeWordWrap; 
		title.numberOfLines = 2;
		//title.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	else {
		title.frame = CGRectMake(rect_x, TITLE_RECT_Y, rect_y, TITLE_RECT_HEIGHT);
	}
	
	rect_x = RECT_START_MARGIN;
	rect_y = DESC_RECT_WIDTH;
	if (imageLink == nil) {
		rect_y += IMG_RECT_WIDTH;
	}
	description = (UILabel*)[cell.contentView viewWithTag:MREADER_DESCRIPTION_TAG];
	if (description == nil) {
		description = [[[UILabel alloc] initWithFrame:CGRectMake(rect_x, DESC_RECT_Y, rect_y, DESC_RECT_HEIGHT)] autorelease];
		description.tag = MREADER_DESCRIPTION_TAG;
		description.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
		description.textColor = [UIColor grayColor];
		description.lineBreakMode = UILineBreakModeTailTruncation;
		description.numberOfLines = 4;
		//description.autoresizingMask = UIViewAutoresizingFlexibleWidth | 	UIViewAutoresizingFlexibleHeight; 
	}
	else {
		description.frame = CGRectMake(rect_x, DESC_RECT_Y, rect_y, DESC_RECT_HEIGHT);
	}
	
	imageRect = (TableCellView*)[cell.contentView viewWithTag:MREADER_IMG_TAG];
	rect_x = rect_x + rect_y + IMG_MARGIN;
	if (imageRect == nil) {
		imageRect = [[[TableCellView alloc] initWithFrame:CGRectMake(rect_x, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT)] autorelease];
		imageRect.tag = MREADER_IMG_TAG;
		imageRect.imageLink = NO_IMAGE_AVAIABLE;
	}
	else {
		imageRect.frame = CGRectMake(rect_x, IMG_RECT_Y, IMG_RECT_WIDTH, IMG_RECT_HEIGHT);
	}
	
	if (imageLink != nil) {		
		// Image link is available.
		//			[storage addImage:image];
		if (imageRect.image == nil) {
			shouldAddImageCell = YES;
		}
		
		if ([imageRect compareImageLink:imageLink] == NO) {
			// new image link is set
			if (([imageRect compareImageLink:DEFAULT_IMAGE] == NO) && (imageRect.image != nil)) 
				[imageRect.image release];
			image = [[UIImage alloc] initWithContentsOfFile:getActualPath(imageLink)];
			if (image == nil) {
				NSLog(@"%s, image is nul: %@", __func__, imageLink);
			}
			imageRect.image = image;
			imageRect.imageLink = imageLink;
			if ((reusableCell == NO) || (shouldAddImageCell == YES))
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
		imageRect.image = nil;
		imageRect.imageLink = DEFAULT_IMAGE;
	}
	else {
		dontDoAnything = YES;
	}
	
	//if (dontDoAnything == YES) {
	//	NSLog(@"tableView: %@, section: %d, row: %d, image: %@", title.text, indexPath.section, indexPath.row, imageLink);
	//}
	
	NSString *text = link.text;
	if ((title.text == nil) || 
		([title.text compare:text] != NSOrderedSame)) {
		title.text = text;
		//NSLog(@"tableView text: %@", title.text);
		[cell.contentView addSubview:title];
	}
	
	NSString *descriptionText = link.description;
	if ((description.text == nil) || 
		([description.text compare:descriptionText] != NSOrderedSame)) {
		description.text = descriptionText;
		[cell.contentView addSubview:description];
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [configuration.history count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{	
	return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)newIndexPath
{ 
	// Open web view
	//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(openWebViewAtIndex:) withObject:(id)newIndexPath waitUntilDone:YES];
	Configuration *config = [Configuration sharedConfigurationInstance];
	
	WebViewController *myWebViewController = [[WebViewController alloc] init];
	//WebViewController *myWebViewController = [WebViewControllerHolder getWebViewController:&needLoad];
	myWebViewController.webLink = [config.history objectAtIndex:newIndexPath.row];
	myWebViewController.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:myWebViewController animated:YES];
	[tableView deselectRowAtIndexPath:newIndexPath animated:YES];
	
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
	[super dealloc];
}


@end
