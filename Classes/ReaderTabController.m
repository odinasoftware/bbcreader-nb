//
//  ReaderTabController.m
//  NYTReader
//
//  Created by Jae Han on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ReaderTabController.h"
#import "ArticleNavigation.h"
#import "ImageNavigation.h"
#import "Configuration.h"
#import "OthersNavigation.h"
#import "WebHistoryNavigation.h"

@implementation ReaderTabController

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
	//self.selectedIndex = 1;
	NSString *last_url = [[Configuration sharedConfigurationInstance] getLastUsedURLHash];
	if (last_url != nil) {
		// display history and the content
		self.selectedIndex = 2;
	}
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	UIViewController *controller = self.selectedViewController;
	if ([controller isKindOfClass:[ArticleNavigation class]] == YES) {
		ArticleNavigation *nav = (ArticleNavigation*)controller;
		
		if (nav.didWebViewShown == YES) {
			// Autorotate only when webview is shown.
			return YES;
		}
	}
	else if ([controller isKindOfClass:[ImageNavigation class]] == YES) {
		ImageNavigation *nav = (ImageNavigation*)controller;
		
		if (nav.didWebViewShown == YES) {
			// Autorotate only when webview is shown.
			return YES;
		}
	}
	else if ([controller isKindOfClass:[OthersNavigation class]] == YES) {
		OthersNavigation *nav = (OthersNavigation*) controller;
		
		if (nav.didWebViewShown == YES) {
			return YES;
		}
	}
	else if ([controller isKindOfClass:[WebHistoryNavigation class]] == YES) {
		WebHistoryNavigation *nav = (WebHistoryNavigation*) controller;
		if (nav.didWebViewShown == YES) {
			return YES;
		}
		
	}
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	//return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	
	//if (toInterfaceOrientation == UIDeviceOrientationLandscapeLeft || toInterfaceOrientation == UIDeviceOrientationLandscapeRight) {
	//	UINavigationController *nav = (UINavigationController*)self.tabBarController.selectedViewController;
	//	nav.navigationBarHidden = YES;
	//}
	//else if (toInterfaceOrientation == UIDeviceOrientationPortrait) {
	//	UINavigationController *nav = (UINavigationController*)self.tabBarController.selectedViewController;
	//	nav.navigationBarHidden = NO;
	//}
	
	//self.tabBarController.view.hidden = YES;
	//theTabBar.hidden = YES; 
	//[theTabBar removeFromSuperview];
	//theTabBar.frame = CGRectMake(0, 0, 0, 0);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (fromInterfaceOrientation == UIDeviceOrientationPortrait) {
		UINavigationController *nav = (UINavigationController*)self.tabBarController.selectedViewController;
		nav.navigationBarHidden = YES;
	}
	else
	if (fromInterfaceOrientation == UIDeviceOrientationLandscapeLeft || fromInterfaceOrientation == UIDeviceOrientationLandscapeRight) {
		UINavigationController *nav = (UINavigationController*)self.tabBarController.selectedViewController;
		nav.navigationBarHidden = NO;
	}
}

/*
- (UIView *)rotatingFooterView
{
	return nil;
}

- (UIView *)rotatingHeaderView
{
	return nil;
}
*/

- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}


@end
