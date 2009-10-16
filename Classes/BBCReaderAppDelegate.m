//
//  NYTReaderAppDelegate.m
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//
#include "MReader_Defs.h"

#import "BBCReaderAppDelegate.h"
#import "NetworkService.h"
#import "ArticleViewController.h"
#import "ArticleNavigation.h"
//#import "HTTPHelper.h"
#import "WebLink.h"
#import "ReaderTabController.h"
#import "OthersNavigation.h"
#import "ImageViewController.h"
#import "OthersViewController.h"
#import "ArticleStorage.h"
#import "SelectedSegmentIndex.h"
#import "ScrollViewController.h"
#import "ImageNavigation.h"
#import "SettingsView.h"
#import "WebViewController.h"
#import "WebViewHistoryController.h"
#import "WebHistoryNavigation.h"
#import "Configuration.h"

#include <sys/socket.h>
#include <sys/select.h>
#include <netdb.h>
#include <arpa/inet.h>

#import <SystemConfiguration/SystemConfiguration.h>

#define OTHERS_VIEW_INDEX	4
#define ARTICLE_NAVIGATION_INDEX 0

@implementation BBCReaderAppDelegate

@synthesize window;
@synthesize tabBarController;

- (void)cleanTempDir 
{
	NSString* tmp;
    tmp = [[NSString alloc] initWithString:NSTemporaryDirectory()];
	NSString* rootLocation = [tmp stringByAppendingPathComponent:@"/cache/"];
	[tmp release];
	tmp = [[NSString alloc] initWithString:NSTemporaryDirectory()];
	NSString* indexLocation = [tmp stringByAppendingPathComponent:@"/index/"];
	[tmp release];

	NSLog(@"Cache: %@", rootLocation);
	NSLog(@"Index: %@", indexLocation);
	
	NSError *error = nil;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];

	[fileManager removeItemAtPath:rootLocation error:&error];
	if (error != nil) {
		NSLog(@"error: %@", error);
	}
	[fileManager removeItemAtPath:indexLocation error:&error];
	if (error != nil) {
		NSLog(@"error: %@", error);
	}
	
	//[rootLocation release];
	//[indexLocation release];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	// Todo: Start background thread and network app
	[Configuration sharedConfigurationInstance];
	
	NSLog(@"RunLoop1: %@", CFRunLoopGetCurrent());
	self.tabBarController.delegate = self;
	reloadArticleData = NO;
	showedNetworkError = NO;
	//[self cleanTempDir];
	/* Just for testing. will it make any difference if this is running in main thread.
 	NSString *mainURLString = @"http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml";
	HTTPHelper *httpService = [[HTTPHelper alloc] init];
	

	NSURL *mainURL = [NSURL URLWithString:mainURLString];
	[httpService requestWithURL:mainURL];
	*/
	
	/*
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:@"kNetworkReachabilityChangedNotification" object:nil];
	SCNetworkReachabilityRef defaultRouteReachability;
	//struct sockaddr_in zeroAddress;
	//bzero(&zeroAddress, sizeof(zeroAddress));
	//zeroAddress.sin_len = sizeof(zeroAddress);
	//zeroAddress.sin_family = AF_INET;
	BOOL gotFlags = NO;
	TRACE("%s\n", __func__);
	
	defaultRouteReachability = SCNetworkReachabilityCreateWithName(NULL, (const char*) "www.apple.com");
	SCNetworkReachabilityFlags flags;
	gotFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	*/
			
	// Add the tab bar controller's current view as a subview of the window
	[window addSubview:tabBarController.view];
	NetworkService *thread = [NetworkService sharedNetworkServiceInstance];
	
	[thread start];
}

- (void)reachabilityChanged:(NSNotification *)note
{
    
	SCNetworkReachabilityRef defaultRouteReachability;
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	BOOL gotFlags = NO;
	TRACE("%s\n", __func__);
	
	defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags;
	gotFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	TRACE("%s, %d, %x\n", __func__, gotFlags, flags);
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController 
{
	if ([viewController isKindOfClass:[ArticleNavigation class]]) {
		// select article view controller
		NSLog(@"Select article view controller\n");
		[[ArticleStorage sharedArticleStorageInstance] switchToArticleNavigation];
		if (reloadArticleData == YES) {
			[[(ArticleViewController*)[(UINavigationController*)viewController visibleViewController] theTableView] reloadData];
			reloadArticleData = NO;
		}
	}
	else if ([viewController isKindOfClass:[OthersNavigation class]]) {
		// select others view controller
		NSLog(@"Select others view controller\n");
		[[ArticleStorage sharedArticleStorageInstance] switchToOthersNavigation];
	}
	
}


/*
 Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/

- (void)addNewArticle:(WebLink*)article  
{
	/* TODO: Is there any better solution?
	 *       If it is done blindly, it will be updating always. 
	 *       Which will be very bad because it will updating the same images all the time.
	 */
	UIViewController *controller = nil;
	
	if ([[self.tabBarController selectedViewController] isKindOfClass:[UINavigationController class]]) {
		controller = 
			[(UINavigationController*)[self.tabBarController selectedViewController] visibleViewController];
		
		if ([controller isKindOfClass:[ArticleViewController class]]) {
			[[(ArticleViewController*)controller theTableView] reloadData];
		}
	}
}

- (void)showNextArticleImage:(WebLink*)article
{
	UIViewController*controller = nil;
	
	if ([[self.tabBarController selectedViewController] isKindOfClass:[UIViewController class]]) {
		controller = (UIViewController*)[self.tabBarController selectedViewController];
		
		if ([controller isKindOfClass:[ImageViewController class]]) {
			[(ImageViewController*)controller showNextImage];
		}
	}
}

- (void)showPrevArticleImage:(WebLink*)article
{
	UIViewController*controller = nil;
	
	if ([[self.tabBarController selectedViewController] isKindOfClass:[UIViewController class]]) {
		controller = (ImageViewController*)[self.tabBarController selectedViewController];
		
		if ([controller isKindOfClass:[ImageViewController class]]) {
			[(ImageViewController*)controller showPrevImage];
		}
	}
}

- (void)updateHistory:(id)object
{
	UIViewController *controller = [(WebHistoryNavigation*)[[self.tabBarController viewControllers] objectAtIndex:2] topViewController];
	
	if ([controller isKindOfClass:[WebViewHistoryController class]]) {
		WebViewHistoryController *history = (WebViewHistoryController*)controller;
		
		[history.theTableView reloadData];
	}
}

- (void)setTitle:(NSString*)title 
{
	[(ArticleNavigation*)[[self.tabBarController viewControllers] objectAtIndex:0] setTitle:title];
}

- (void)showPreviousFeed:(id)object
{
	[(ArticleNavigation*)[[self.tabBarController viewControllers] objectAtIndex:0] showPreviousFeed];
}


- (void)reloadArticleWithIndex:(id)index
{
	/*
	UIViewController* controller = 
		[(UINavigationController*)[self.tabBarController selectedViewController] visibleViewController];
	
	if ([controller isKindOfClass:[ArticleViewController class]]) {
		[[(ArticleViewController*)controller theTableView] reloadData];
	}
	*/	
	SelectedSegmentIndex *segmentIndex = (SelectedSegmentIndex*)index;
	reloadArticleData = YES;
	[(ArticleNavigation*)[[self.tabBarController viewControllers] objectAtIndex:0] updateSegmentText:(int)segmentIndex.index];
	
}

/*
- (void)openWebViewAtIndex:(NSIndexPath*)indexPath
{
	NSUInteger selectedIndex = [self.tabBarController selectedIndex];
	
	// TODO: need to better way to provide index, because it's not the real index for a feed
	NetworkService *servcie = [NetworkService sharedNetworkServiceInstance];
	[servcie setCurrentWebIndex:indexPath];
	
	if (selectedIndex == 0) {
		[(ArticleNavigation*)[[self.tabBarController viewControllers] objectAtIndex:selectedIndex] showWebView:indexPath];
	}
	else if (selectedIndex == 2) {
		[(WebHistoryNavigation*)[[self.tabBarController viewControllers] objectAtIndex:selectedIndex] showWebView:indexPath];
	}
	else if (selectedIndex == OTHERS_VIEW_INDEX) {
		[(OthersNavigation*)[[self.tabBarController viewControllers] objectAtIndex:selectedIndex] showWebView:indexPath];
	}
	
}


- (void)openWebViewWithRequest:(NSURLRequest*)request
{
	NSUInteger selectedIndex = [self.tabBarController selectedIndex];
	
	if (selectedIndex == 0) {
		[(ArticleNavigation*)[[self.tabBarController viewControllers] objectAtIndex:selectedIndex] showWebViewWithRequest:request];
	}
	else if (selectedIndex == OTHERS_VIEW_INDEX) {
		[(OthersNavigation*)[[self.tabBarController viewControllers] objectAtIndex:OTHERS_VIEW_INDEX] showWebViewWithRequest:request];
	}
}

- (void)openWebViewWithLink:(WebLink*)link
{
	NSUInteger selectedIndex = [self.tabBarController selectedIndex];
	if (selectedIndex == 1) {
		[(ImageNavigation*)[self.tabBarController selectedViewController] showWebView:link];
	}
}
*/

- (void)showImageControls:(id)object
{
	UIViewController *controller = [self.tabBarController selectedViewController];
	
	if ([controller isKindOfClass:[UINavigationController class]]) {
		UINavigationController *nav = (UINavigationController*)controller;
		[(ScrollViewController*)nav.visibleViewController showImageControls:object];
	}
}

- (void)updateImageLink:(id)object
{
	UIViewController *controller = [self.tabBarController selectedViewController];
	
	if ([controller isKindOfClass:[ImageNavigation class]]) {
		UIViewController *embedded = ((ImageNavigation*)controller).visibleViewController;
		if ([embedded isKindOfClass:[ScrollViewController class]]) {
			[(ScrollViewController*)embedded updateImage];
		}
	}
}

- (void)updateSegmentTitles:(id)object
{
	
	UIViewController *controller = [[self.tabBarController viewControllers] objectAtIndex:ARTICLE_NAVIGATION_INDEX];

	if ([controller isKindOfClass:[ArticleNavigation class]]) {
		[(ArticleNavigation*)controller updateSegmentTitles];
	}
	
}

- (void)showNetworkError:(id)object
{
	UIViewController *controller = [self.tabBarController selectedViewController];
	
	if ([controller isKindOfClass:[UINavigationController class]]) {
		UIViewController *tableController = ((UINavigationController*)controller).visibleViewController;
		if ([tableController isKindOfClass:[ArticleViewController class]]) {
			[(ArticleViewController*)tableController showNetworkError];
		}
	}

	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	
	if (service.offlineMode == NO && showedNetworkError == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet Not Working" message:@"Internet is not working properly. Please check your Internet connection."
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
		showedNetworkError = YES;
	}
}

- (void)showEmptyCacheWarning:(id)object
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Cache" message:@"BBCReader has been updated. Cache will be cleaned. Articles will be synced after the cleanup."
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}

- (void)showOfflineModeWarning:(id)object
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You are in offline mode" message:@"Your cache is empty and BBCReader will not fetch any articles. Please disable offline mode and restart BBCReader to sync articles."
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}

- (void)displaySlowNetworkWarning:(id)object
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Slow network detected" message:@"Your Internet is slow than usual. Do you want to continue updating articles?"
												   delegate:object cancelButtonTitle:@"Continue" otherButtonTitles:@"Stop",nil];
	[alert show];
	[alert release];
}



- (void)removeSplashView:(id)object
{
	UIViewController *controller = [self.tabBarController selectedViewController];
	
	if ([controller isKindOfClass:[UINavigationController class]]) {
		UIViewController *inside = ((UINavigationController*)controller).visibleViewController;
		if ([inside isKindOfClass:[WebViewController class]]) {
			[(WebViewController*)inside removeSplashView];
		}
	}
}

- (void)displayDiskWarning:(id)object
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"UIAlertView" message:@"You do not have enough cache space.\n25MBytes will be needed at least."
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}

- (void)dealloc {
	[tabBarController release];
	[window release];
	[super dealloc];
}

@end

