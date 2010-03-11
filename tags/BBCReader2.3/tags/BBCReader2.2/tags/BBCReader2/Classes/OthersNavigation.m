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
	
	if (self.topViewController == nil) {
		OthersViewController *othersView = [[OthersViewController alloc] initWithNibName:@"OthersView" bundle:nil];
		[self pushViewController:othersView animated:NO];
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
