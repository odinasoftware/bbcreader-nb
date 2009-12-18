//
//  ArticleNavigation.m
//  NYTReader
//
//  Created by Jae Han on 7/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ArticleNavigation.h"
#import	"ArticleViewController.h"
#import "ArticleStorage.h"
#import "NetworkService.h"
#import "WebViewController.h"
#import "WebViewControllerHolder.h"

#define kSegmentCtrlBoxSize		280.0
#define kSegmentCtrlBoxYOrigin	5.0
#define kSegmentCtrlBoxHeight	30.0


@implementation ArticleNavigation

@synthesize didWebViewShown;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		//useSecondView = YES;
		prevSelection = -1;
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */


- (void)viewDidLoad {
	self.delegate = self;
	// TODO: need to modify to get it from user.
	if (self.topViewController == nil) {
		ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
		[storage setActiveFeed:0];
		didWebViewShown = NO;
		
		ArticleViewController *articleView = [[ArticleViewController alloc] initWithNibName:@"ArticleView" bundle:nil];
		//secondView = [[ArticleViewController alloc] initWithNibName:@"ArticleView" bundle:nil];
		/* TODO: this bar button item does not work.
		 articleView.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		 target:nil
		 action:nil] autorelease];
		 articleView.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		 target:nil
		 action:nil] autorelease];
		 */
		
		[self pushViewController:articleView animated:NO];
		NSArray *titles = [storage getMostRecentTitles];
		theSegmentedControl = [[UISegmentedControl alloc] initWithItems:titles];
		[theSegmentedControl addTarget:self action:@selector(toggleSection:) forControlEvents:UIControlEventValueChanged];
		theSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		theSegmentedControl.backgroundColor = [UIColor clearColor];
		[theSegmentedControl sizeToFit];
		theSegmentedControl.selectedSegmentIndex = 0;
		CGRect parentFrame = [self.navigationBar frame];
		CGRect segmentedControlFrame = CGRectMake(parentFrame.size.width/2 - kSegmentCtrlBoxSize/2,
												  parentFrame.size.height/2 - kSegmentCtrlBoxHeight/2,
												  kSegmentCtrlBoxSize,
												  kSegmentCtrlBoxHeight);
		theSegmentedControl.frame = segmentedControlFrame;
		//[self.navigationBar addSubview:theSegmentedControl];
		//[segmentedControl release];	
		[titles release];
	}
}

- (void)updateSegmentText:(int)index
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	NSString *text = [storage getTextForSegmentIndex:index];
	
	[theSegmentedControl setTitle:text forSegmentAtIndex:index];
}

- (void)updateSegmentTitles
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	NSArray *titles = [storage getMostRecentTitles];
	for (int i=0; i<theSegmentedControl.numberOfSegments; ++i) {
		[theSegmentedControl setTitle:[titles objectAtIndex:i] forSegmentAtIndex:i];
	}
	[titles release];
	[((ArticleViewController*)self.topViewController).theTableView reloadData];
}

- (void)toggleSection:(id)sender
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	int selection = [sender selectedSegmentIndex];
	
	switch (selection)
	{
		case 0:	
		{
			[storage showRecentArticle:0];
			break;
		}
		case 1: 
		{	
			[storage showRecentArticle:1];
			break;
		}
		case 2:	
		{
			[storage showRecentArticle:2];
			break;
		}
	}
	
	if (selection != prevSelection) {
		prevSelection = selection;
		[storage drainImage];
	}
	
}

- (void)showPreviousFeed
{
	[self popViewControllerAnimated:YES];
}

- (void)showWebView:(NSIndexPath*)indexPath
{
	//BOOL needLoad = NO;
	
	//WebViewController* webView = [[WebViewController alloc] initWithNibName:@"WebView" bundle:nil];
	WebViewController *myWebViewController = [[WebViewController alloc] init];
	//WebViewController *myWebViewController = [WebViewControllerHolder getWebViewController:&needLoad]; 
	
	myWebViewController.theIndexPath = indexPath;
	myWebViewController.hidesBottomBarWhenPushed = YES;
	
	
	// TODO: Decide start a thread or use the network thread for local server.
	// Using local server thread:
	//    achieve responsivness, however be careful to finish the current one ASAP. 
	// 
	// Use network thread:
	//    easy to sync, but may have some problem in responsivness.
	//[theSegmentedControl removeFromSuperview];
	pool = [[NSAutoreleasePool alloc] init];
	//if (needLoad == NO)
	[self pushViewController:myWebViewController animated:YES];
	//[myWebViewController release];
	//else {
	//	[self pushViewController:myWebViewController animated:YES];
	//	[myWebViewController loadWeb];
	//}
}

- (void)showWebViewWithRequest:(NSURLRequest*)request
{
	//myWebViewController = [[WebViewController alloc] initWithNibName:@"WebView" bundle:nil];
	WebViewController *myWebViewController = [[WebViewController alloc] init];
	//webView.request = request;
	myWebViewController.hidesBottomBarWhenPushed = YES;
	
	// TODO: Decide start a thread or use the network thread for local server.
	// Using local server thread:
	//    achieve responsivness, however be careful to finish the current one ASAP. 
	// 
	// Use network thread:
	//    easy to sync, but may have some problem in responsivness.
	//[theSegmentedControl removeFromSuperview];
	
	[self pushViewController:myWebViewController animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isKindOfClass:[ArticleViewController class]]) {
		[pool release];
	}
	
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	
	if ([viewController isKindOfClass:[ArticleViewController class]]) {
		[self.navigationBar addSubview:theSegmentedControl];
		service.changeToLocalServerMode = NO;
		[service.doSomething broadcast];
		didWebViewShown = NO;
	}
	else if ([viewController isKindOfClass:[WebViewController class]]) {
		
		service.changeToLocalServerMode = YES;
		[theSegmentedControl removeFromSuperview];
		//self.navigationBar.backItem.title = @"test";
		didWebViewShown = YES;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	//NSLog(@"%s, %d", __func__, didWebViewShown);
	if (didWebViewShown == YES) {
		return YES;
	}
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	//return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
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
