//
//  WebHistoryNavigation.m
//  NYTReader
//
//  Created by Jae Han on 11/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"
#import "WebHistoryNavigation.h"
#import "WebViewHistoryController.h"
#import "WebViewController.h"
#import "Configuration.h"
#import "WebViewControllerHolder.h"


@implementation WebHistoryNavigation

@synthesize didWebViewShown;

/*
// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
	didWebViewShown = NO;
	WebViewHistoryController *historyView = [[WebViewHistoryController alloc] initWithNibName:@"WebHistory" bundle:nil];
	[self pushViewController:historyView animated:NO];
	
	/*
	Configuration *config = [Configuration sharedConfigurationInstance];
	NSString *last_url_hash = [config getLastUsedURLHash];
	if (last_url_hash != nil) {
		WebLink *link = [config getHistoryLinkFromURL:last_url_hash];
		if (link) {
			WebViewController *myWebViewController = [[WebViewController alloc] init];
			myWebViewController.webLink = link;
			
			//webView.hidesBottomBarWhenPushed = YES;
			[self pushViewController:myWebViewController animated:YES];
		}
	}
	 */
    //[super viewDidLoad];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isKindOfClass:[WebViewHistoryController class]]) {
		[pool release];
	}
	
}
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isKindOfClass:[WebViewController class]]) {
		didWebViewShown = YES;
	}
	else if ([viewController isKindOfClass:[WebViewHistoryController class]]) {
		didWebViewShown = NO;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end
