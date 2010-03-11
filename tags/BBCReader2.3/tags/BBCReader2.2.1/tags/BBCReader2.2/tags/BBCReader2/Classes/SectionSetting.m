//
//  SectionSetting.m
//  BBCReader
//
//  Created by Jae Han on 1/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "SectionSetting.h"
#import "ArticleStorage.h"

#define kSegmentCtrlBoxSize		280.0
#define kSegmentCtrlBoxYOrigin	5.0
#define kSegmentCtrlBoxHeight	30.0



@implementation SectionSetting

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];

	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
									 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
	
	self.navigationItem.prompt = @"Select article sections";
	self.navigationItem.leftBarButtonItem = cancelButton;
	[cancelButton release];

	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
	
	[super viewDidLoad];
	
	NSArray *titles = [storage getMostRecentTitles];
	int i = 0;
	for (NSString *t in titles) {
		[segmentedControl setTitle:t forSegmentAtIndex:i++];
	}
	[titles release];
	
	self.navigationItem.title = @"Select sections";
	manual.numberOfLines = 4;
	manual.text = @"First choose a segment you would like to change, then pick your section.";
	
	selectedFeed = 0;
	selectedSegment = 0;

	for (i=0; i<3; ++i) {
		segmentIndexes[i] = [storage getFeedIndexForSegment:i];
	}
	
	segmentedControl.selectedSegmentIndex = storage.theActiveFeed;
}

- (void)cancelAction:(id)sender
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)doneAction:(id)sender
{
	if (segmentIndexes[0] != segmentIndexes[1] && 
		segmentIndexes[0] != segmentIndexes[2] &&
		segmentIndexes[1] != segmentIndexes[2]) {
		[self.navigationController dismissModalViewControllerAnimated:YES];
		//save segmentIndexes to activeFeed
		// TODO: check any duplication and display warning if there is any
		ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
		[storage setToActiveFeed:segmentIndexes];
	}
	else {
		 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Duplicate section" message:@"One of your segment settings has duplicate item. Please select unique section for each segment."
		 delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		 [alert show];
		 [alert release];

	}
}

- (IBAction)toggleSelection:(id)sender
{
	int selection = [sender selectedSegmentIndex];
	
	TRACE("%s, selection: %d\n", __func__, selection);
	selectedSegment = selection;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	//ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	return 2;//[storage numberOfFeedSections];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	if (component == 0) 
		return 2;
	return [storage numberOfFeeds:selectedFeed];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	TRACE("%s, row:%d, component:%d\n", __func__, row, component);
	if (component == 0) {
		if (selectedFeed != row) {
			selectedFeed = row;
			[pickerView reloadComponent:1];
		}
	}
	else {
		ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
		NSString *t = [storage getSectionTitle:row withComponent:component bySelection:selectedFeed];
		[segmentedControl setTitle:t forSegmentAtIndex:selectedSegment];
		segmentIndexes[selectedSegment] = [storage getArticleIndexWith:row andSelection:selectedFeed];
	}
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	TRACE("%s, row: %d, component: %d, feed: %d\n", __func__, row, component, selectedFeed);
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	return [storage getSectionTitle:row withComponent:component bySelection:selectedFeed];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end
