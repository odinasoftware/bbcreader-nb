//
//  ScrollViewController.m
//  NYTReader
//
//  Created by Jae Han on 10/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "ScrollViewController.h"
#import	"ArticleStorage.h"
#import "ImageViewController.h"
#import "ArticleScrollView.h"
#import "WebViewController.h"
#import "WebLink.h"

#define SCROLL_VIEW_HEIGHT		365.0
#define MAX_CONTROLLER_NUM		3
#define reflectionFraction		0.35
#define reflectionOpacity		0.5
#define INITIAL_SLIDE_IMAGE		3


@implementation PageViewControllerPointer

@synthesize controller;
@synthesize page;
//@synthesize link;

- (id)initWithPage:(NSInteger)num
{
	if (self = [super init]) {
		page = num;
		controller = nil;
		//link = nil;
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

@end


@implementation ScrollViewController


// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		frontViewIsVisible = YES;
		currentWebLink = nil;
		storage = [ArticleStorage sharedArticleStorageInstance];
	}
    return self;
}

- (id)init
{
	if (self = [super init]) {
		frontViewIsVisible=YES;
		currentWebLink = nil;
	}
	return self;
}

/*
// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
}
*/

- (ImageViewController*)getNextImageViewControllerWithPage:(NSInteger)page needRedraw:(BOOL*)redraw
{
	int target = -1;
	
	TRACE("%s, cur: %d, page: %d\n", __func__, currentPage, page);
	
	if (currentPage == page || currentPage == -1) {
		// increasing
		target = currentArrayPointer;
		currentArrayPointer = (currentArrayPointer + 1) % MAX_CONTROLLER_NUM;
	}
	else if (currentPage == page + 2) {
		// decreasing
		currentArrayPointer--;
		if (currentArrayPointer < 0)
			currentArrayPointer = MAX_CONTROLLER_NUM - 1;
		target = currentArrayPointer;
	}
	else {
		NSLog(@"%s, unknown case: cur: %d, page: %d",__func__, currentPage, page);
		return nil;
	}
	
	PageViewControllerPointer *pointer = [controllerArray objectAtIndex:target];
	if (pointer.controller == nil) {
		pointer.controller = [[ImageViewController alloc] initWithNibName:@"ImageView" withPage:page];
		//pointer.link = [storage getArticleAtPage:page]; //pointer.controller.webLink;
		pointer.controller.view.tag = page;
		*redraw = NO;
	}
	else {
		*redraw = YES;
		[pointer.controller.view removeFromSuperview];
		pointer.controller.view.tag = page;
		
		//pointer.link = [storage getArticleAtPage:page];
	}
	//TRACE("%s, page: %d, link: %p\n", __func__, page, pointer.link);
	
	pointer.page = page;

	return pointer.controller;
}

- (void)addToControllerArray:(ImageViewController*)controller withPage:(NSInteger)page forLink:(WebLink*)link
{
#define NUMBER_OF_SLIDES 3
	int target = -1;
	
	TRACE("%s, cur: %d, page: %d\n", __func__, currentPage, page);
	
	if (currentPage == page || currentPage == -1) {
		// increasing
		target = currentArrayPointer;
		currentArrayPointer = (currentArrayPointer + 1) % MAX_CONTROLLER_NUM;
	}
	else if (currentPage == page + 2) {
		// decreasing
		currentArrayPointer--;
		if (currentArrayPointer < 0)
			currentArrayPointer = MAX_CONTROLLER_NUM - 1;
		target = currentArrayPointer;
	}
	else {
		NSLog(@"%s, unknown case: cur: %d, page: %d",__func__, currentPage, page);
		return;
	}
	
	
	TRACE("????: ");
	for (int i=0; i<MAX_CONTROLLER_NUM; ++i) {
		PageViewControllerPointer *p = [controllerArray objectAtIndex:i];
		if (p) {
			TRACE("(index: %d, page: %d) ", i, p.page);
		}
	}
	TRACE(": cur: %d\n", currentArrayPointer);
	
	PageViewControllerPointer *pointer = [controllerArray objectAtIndex:target];
	if (pointer.controller != nil) {
		TRACE("%s, detect unreleased controller: %d, replaced to: %d\n", __func__, pointer.page, page);
		[pointer.controller.view removeFromSuperview];
		[pointer.controller release]; 
		//[pointer.link release];
	}
	pointer.controller = controller;
	pointer.page = page;
	//pointer.link = link;
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
	self.navigationItem.title = @"Pictures";
	playBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideShow:)];
	stopBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(stopSlideShow:)];
	
	controllerArray = [[NSArray alloc] initWithObjects:
					   [[PageViewControllerPointer alloc] initWithPage:-1],
					   [[PageViewControllerPointer alloc] initWithPage:-1],
					   /*[[PageViewControllerPointer alloc] initWithPage:-1],*/
					   [[PageViewControllerPointer alloc] initWithPage:-1], nil];
	currentArrayPointer = 0;
	currentPage = -1;
	
	UINavigationItem *navItem = self.navigationItem;
	navItem.rightBarButtonItem = playBarButton;
	
	self.view.backgroundColor = [UIColor blackColor];
	numberOfPages = [[ArticleStorage sharedArticleStorageInstance] getNumberOfImages];
	
	//scrollView.autoresizingMask = UIViewAutoresizingNone;
	//toolBar.autoresizingMask = UIViewAutoresizingNone;
	scrollView.backgroundColor = [UIColor blackColor];
	scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * numberOfPages, SCROLL_VIEW_HEIGHT);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
	
	[[ArticleStorage sharedArticleStorageInstance] initScrollablePage];
		
	// TODO: But, what if there is less then three images are avilable and
	//       how to cope with changing size of slide number.
	int i = 0;
	for (i=0; i<INITIAL_SLIDE_IMAGE; ++i) {
		WebLink *link = [self loadImageView:i];
		if (i == 0) {
			currentWebLink = link;
		}
	}
	currentPage = i-1; // represent the last loaded page
	currentSelectedPage = 0;
	isSlideShowRunning = NO;
	
    [super viewDidLoad];
}

- (WebLink*)loadImageView:(NSInteger)page 
{
	BOOL shouldRedraw = NO;
	
	ImageViewController *controller = [self getNextImageViewControllerWithPage:page needRedraw:&shouldRedraw];
	//[[ImageViewController alloc] initWithNibName:@"ImageView" withPage:page];
	
	CGRect frame = scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	controller.view.frame = frame;
	
	if (shouldRedraw == NO) {
		
		[scrollView addSubview:controller.view];
		//[self addToControllerArray:controller withPage:page forLink:controller.webLink];
	}
	else {
		
		[controller reDrawWithPage:page];
		
		[scrollView addSubview:controller.view];
		
		
	}
	
	return controller.webLink;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	//toolBar.hidden = YES;
	//self.navigationController.navigationBarHidden = YES;
	//navigationBar.hidden = YES;
}

- (void)showImageControls:(id)object 
{
	//toolBar.hidden = NO;
	//navigationBar.hidden = NO;
	//self.navigationController.navigationBarHidden = NO;
	NSNumber *tapCount = (NSNumber*)object;
	
	if (isSlideShowRunning == NO && [tapCount intValue] == 2) {
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(openWebViewWithLink:) withObject:(id)currentWebLink waitUntilDone:YES];
	}
	else if (isSlideShowRunning == YES && [tapCount intValue] > 0) {
		[self stopSlideShow:nil];
	}
	
}

- (void)cleanController:(NSInteger)page
{
	for (PageViewControllerPointer* ptr in controllerArray) {
		if (ptr.page == page) {
			ptr.page = -1;
			[ptr.controller release]; // since it is retained.
			[ptr.controller release]; // to remove this instance.
			NSLog(@"%s, remove this controller: %d", __func__, page);
		}
	}
}

- (WebLink*)getWebLink:(NSInteger)page
{
	WebLink *link = nil;
	
	for (PageViewControllerPointer* ptr in controllerArray) {
		if (ptr.page != -1 && ptr.page == page) {
			link = ptr.controller.webLink;
			break;
		}
	}
	
	return link;
}

- (ImageViewController*)getImageControllerWithPage:(NSInteger)page
{
	ImageViewController* controller = nil;
	
	for (PageViewControllerPointer* ptr in controllerArray) {
		if (ptr.page != -1 && ptr.page == page) {
			controller = ptr.controller;
			break;
		}
	}
	
	return controller;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
    // Switch the indicator when more than 50% of the previous/next page is visible
	if (isSlideShowRunning == YES) {
		[self stopSlideShow:nil];
	}
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
	if (page == 0) {
		// special case.
	}
	else if (page ==  currentPage) {
		TRACE("---> %s: next page: %d, cur: %d\n", __func__, page, currentPage);
		// Page is increasing, we just need to get the next page
		++currentPage;
		[self loadImageView:currentPage];
		//[self cleanController:currentPage-2];
		
	}
	else if (page+2 == currentPage) {
		TRACE("---> %s: previous page: %d, cur: %d\n", __func__, page, currentPage);
		// Page is decreasing, we just need to get the previous page
		if (currentPage > 0)
			--currentPage;
		[self loadImageView:page-1];
		//[self cleanController:currentPage+2];
		
	}
	
	currentSelectedPage = page;
	currentWebLink = [self getWebLink:page];
	TRACE("%s, page: %d, link: %p\n", __func__, page, currentWebLink);
	//else {
	//	NSLog(@"%s, shouldn't scroll page: %d, cur: %d", __func__, page, currentPage);
	//}
	
	//NSLog(@"%s: page: %d, cur: %d", __func__, page, currentPage);

}

- (void)stopSlideShow:(id)sender
{
	self.navigationItem.rightBarButtonItem = playBarButton;
	isSlideShowRunning = NO;
	if (slideShowTimer != nil) {
		[slideShowTimer invalidate];
		[slideShowTimer release];
	}
	currentWebLink = currentSlideImageController.webLink;
}

- (void)playSlideShow:(id)sender
{
	self.navigationItem.rightBarButtonItem = stopBarButton;
	
	currentSlideImageController = [self getImageControllerWithPage:currentSelectedPage];
	if (currentSlideImageController == nil) {
		NSLog(@"%s, target is null: %d", __func__, currentSelectedPage);
	}
	//toolBar.hidden = YES;
	// TODO: Need to remove timer at some point.
	NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop]; 
	// Create and schedule the first timer. 
	NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:1.0]; 
	slideShowTimer = [[NSTimer alloc] initWithFireDate:futureDate 
												interval:3
												target:currentSlideImageController
												selector:@selector(showNextImage:) 
												userInfo:nil 
												repeats:YES]; 
	[myRunLoop addTimer:slideShowTimer forMode:NSDefaultRunLoopMode]; 
	isSlideShowRunning = YES;
}

- (void)updateImage
{
	numberOfPages++;
	scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * numberOfPages, SCROLL_VIEW_HEIGHT);
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (isSlideShowRunning == YES) {
		[self stopSlideShow:nil];
	}
}

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
