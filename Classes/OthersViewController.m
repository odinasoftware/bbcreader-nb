//
//  OthersViewController.m
//  NYTReader
//
//  Created by Jae Han on 8/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"
#import "OthersViewController.h"
#import "FeedInformation.h"
#import "ArticleStorage.h"
#import	"NetworkService.h"
#import "WebViewController.h"
#import "ArticleViewController.h"

@implementation OthersViewController

//@synthesize theTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		self.title = @"Choose sections";
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
- (void)viewDidLoad 
{
}
*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* identity = @"SectionCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identity];
	
	ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identity] autorelease];
	}
	
	FeedInformation *feed = [storage feedByIndexPath:indexPath]; //[storage.feedInformationStorage objectAtIndex:indexPath.row];
	cell.textLabel.text = feed.title;
	if ([storage isAvailableOffline:indexPath] == YES) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	//UITableViewCellAccessoryDetailDisclosureButton; 
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	//ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	//return [storage countSection];
	return 3;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)newIndexPath
{ 
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	[service setCurrentWebIndex:newIndexPath];
	
	[service performSelectorOnMainThread:@selector(selectArticleAtIndexPath:) withObject:(id)newIndexPath waitUntilDone:YES];

	ArticleViewController* articleView = [[ArticleViewController alloc] initWithNibName:@"ArticleView" bundle:nil];
	articleView.viewMode = OTHER_ARTICLE_MODE;
	[self.navigationController pushViewController:articleView animated:YES];
	
		
	[tableView deselectRowAtIndexPath:newIndexPath animated:YES];
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
 {
 }
 */

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section 
{
	ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	return [storage countInSection:section]; //[storage.feedInformationStorage count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	NSString *title;
	//NSLog(@"%s, section: %d", __func__, section);
	//ArticleStorage* storage = [ArticleStorage sharedArticleStorageInstance];
	//return [storage getTitleInSection:section];
	if (section == 0) {
		title = @"BBC World News";
	}
	else if (section == 1) {
		title = @"BBC Mobile";
	}
	else {
		title = @"BBC Sports";
	}
	return title;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return @"Cached contents are available in the blue disclosure arrow buttons.";
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


- (void)dealloc {
	[super dealloc];
}


@end
