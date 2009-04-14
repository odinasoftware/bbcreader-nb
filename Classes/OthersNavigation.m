//
//  OthersNavigation.m
//  NYTReader
//
//  Created by Jae Han on 8/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OthersNavigation.h"
#import "OthersViewController.h"
#import "ArticleViewController.h"
#import "WebViewController.h"
#import "WebViewControllerHolder.h"
#import	"NetworkService.h"


@implementation OthersNavigation

@synthesize didWebViewShown;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
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
	didWebViewShown = NO;
	self.delegate = self;
	
	OthersViewController *othersView = [[OthersViewController alloc] initWithNibName:@"OthersView" bundle:nil];
	[self pushViewController:othersView animated:NO];
}

- (void)selectArticleAtIndexPath:(NSIndexPath*)indexPath
{
	ArticleViewController* articleView = [[ArticleViewController alloc] initWithNibName:@"ArticleView" bundle:nil];
	articleView.viewMode = OTHER_ARTICLE_MODE;
	[self pushViewController:articleView animated:YES];

}

- (void)showWebView:(NSIndexPath*)indexPath
{
	//BOOL needLoad = NO;
	
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
	didWebViewShown = YES;
}

- (void)showWebViewWithRequest:(NSURLRequest*)request
{
	BOOL needLoad = NO;
	
	WebViewController *myWebViewController = [WebViewControllerHolder getWebViewController:&needLoad];
	//webView.request = request;
	myWebViewController.hidesBottomBarWhenPushed = YES;
	
	// TODO: Decide start a thread or use the network thread for local server.
	// Using local server thread:
	//    achieve responsivness, however be careful to finish the current one ASAP. 
	// 
	// Use network thread:
	//    easy to sync, but may have some problem in responsivness.
	//[theSegmentedControl removeFromSuperview];
	if (needLoad == NO)
		[self pushViewController:myWebViewController animated:YES];
	else {
		[self pushViewController:myWebViewController animated:YES];
		[myWebViewController loadWeb];
	}
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
	
	if ([viewController isKindOfClass:[WebViewController class]]) {
		service.changeToLocalServerMode = YES;
		didWebViewShown = YES;
	}
	else if ([viewController isKindOfClass:[ArticleViewController class]]) {
		service.changeToLocalServerMode = NO;
		[service.doSomething broadcast];
		didWebViewShown = NO;
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
