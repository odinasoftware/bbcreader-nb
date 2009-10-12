//
//  ImageNavigation.m
//  NYTReader
//
//  Created by Jae Han on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ImageNavigation.h"
#import "ScrollViewController.h"
#import "WebViewController.h"
#import "WebViewControllerHolder.h"
#import "NetworkService.h"

@implementation ImageNavigation

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
- (void)viewDidLoad {
	ScrollViewController *scrollView = [[ScrollViewController alloc] initWithNibName:@"ScrollView" bundle:nil];
	[self pushViewController:scrollView animated:NO];
	self.navigationBar.barStyle = UIBarStyleBlackOpaque;
	//self.navigationBarHidden = YES;
    //[super viewDidLoad];
	self.delegate = self;
	didWebViewShown = NO;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isKindOfClass:[ScrollViewController class]]) {
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
	else if ([viewController isKindOfClass:[ScrollViewController class]]) {
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
