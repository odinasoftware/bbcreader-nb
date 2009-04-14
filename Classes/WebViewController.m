//
//  WebViewController.m
//  NYTReader
//
//  Created by Jae Han on 9/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include <sys/file.h>
#include <netdb.h>
#include "MReader_Defs.h"

#import "WebViewController.h"
#import "ArticleStorage.h"
#import "WebLink.h"
#import "NetworkService.h"
#import "Configuration.h"

#define WEB_VIEW_TAG 10

static const NSString *local_host_prefix = @"http://localhost:9000/";
extern BOOL localServerStarted;

@implementation WebViewController

@synthesize theIndexPath;
@synthesize webLink;
//@synthesize request;

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
- (void)loadView 
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
	ArticleStorage *storage = nil;
	WebLink *link = nil;
	BOOL useRequest = NO;
	
	//theWebView.scalesPageToFit = YES;
	//theWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	//theWebView.delegate = self;
	//self.hidesBottomBarWhenPushed = YES;
	requireToStop = NO;
	
	CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
	theWebView = [[UIWebView alloc] initWithFrame:webFrame];
	theWebView.backgroundColor = [UIColor whiteColor];
	theWebView.scalesPageToFit = YES;
	theWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	theWebView.delegate = self;
	self.view = theWebView;
	[theWebView release];
	
	if (theIndexPath != nil) {
		storage = [ArticleStorage sharedArticleStorageInstance];
		link = [storage getSelectedLink:theIndexPath];
		
	}
	else if (webLink != nil) {
		link = webLink;
	}
	//else if (request != nil) {
	//	useRequest = YES;
	//}
	else {
		NSLog(@"%s, index path and weblink is null.", __func__);
		return;
	}
	
	description = link.description;
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	[config addWebHitory:link];

	//NSString *url = [[WebCacheService sharedWebCacheServiceInstance] getLocalName:link.url];
	// create our progress indicator for busy feedback while loading web pages,
	// make it our custom right view in the navigation bar
	//
	CGRect frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	progressView = [[UIActivityIndicatorView alloc] initWithFrame:frame];
	progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
	progressView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
									 UIViewAutoresizingFlexibleRightMargin |
									 UIViewAutoresizingFlexibleTopMargin |
									 UIViewAutoresizingFlexibleBottomMargin);
	
	UINavigationItem *navItem = self.navigationItem;
	buttonItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];
	navItem.rightBarButtonItem = buttonItem;
	
	//[progressView release];
	//[buttonItem release];
	
	[(UIActivityIndicatorView *)navItem.rightBarButtonItem.customView startAnimating];	
	
	/*
	UIImage *splash = [self getSlideImage];
	splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 480)];
	splashView.image = splash;
	splashView.backgroundColor = [UIColor blackColor];
	[theWebView addSubview:splashView];
	 */
	
	if (useRequest == NO) {
		CGRect titleFrame = CGRectMake(0, 5, 200, 40);
		titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
		titleLabel.numberOfLines = 2;
		titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
		titleLabel.textColor = [UIColor whiteColor];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.textAlignment = UITextAlignmentCenter;
		titleLabel.text = link.text;
		navItem.titleView = titleLabel;
		//navItem.title = link.text;
		
		// to register localhost name		
		
		NSString *url = [local_host_prefix stringByAppendingString:link.url];
		realURL = [[NSURL alloc] initWithString:link.url];
		TRACE("%s: %s, %d\n", __func__, [url UTF8String], localServerStarted);
				
		[theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];	
		//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"file:///var/folders/Uv/UvZ97-wrGH8OcAyNxLfLOU+++TI/-Tmp-/cache/newsrss.bbc.co.uk/1010012844.stm"]];
	}
	//else {
	//	[theWebView loadRequest:request];	
	//}
	
    [super viewDidLoad];
}

- (BOOL)isLoadingPage
{
	return theWebView.loading;
}

- (void)stopLoading
{
	[theWebView stopLoading];
}

- (void)loadWeb
{
	ArticleStorage *storage = nil;
	WebLink *link = nil;
	BOOL useRequest = NO;
	
	if (theWebView.loading == YES) {
		NSLog(@"%s, second request detected, will just return.", __func__);
		return;
	}
	/*
	if (theWebView.loading == YES) {
		requireToStop = YES;
		[theWebView stopLoading];
		return;
	}
	else {
		requireToStop = NO;
	}
	 */
	
	if (theIndexPath != nil) {
		storage = [ArticleStorage sharedArticleStorageInstance];
		link = [storage getSelectedLink:theIndexPath];
	}
	else if (webLink != nil) {
		link = webLink;
	}
	//else if (request != nil) {
	//	useRequest = YES;
	//}
	else {
		NSLog(@"%s, index path and weblink is null.", __func__);
		return;
	}
	description = link.description;
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	[config addWebHitory:link];
	
	//NSString *url = [[WebCacheService sharedWebCacheServiceInstance] getLocalName:link.url];
	// create our progress indicator for busy feedback while loading web pages,
	// make it our custom right view in the navigation bar
	//
		
	UINavigationItem *navItem = self.navigationItem;
	//buttonItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];
	navItem.rightBarButtonItem = buttonItem;
	progressView.hidden = NO;
	
	//[progressView release];
	//[buttonItem release];
	
	[(UIActivityIndicatorView *)navItem.rightBarButtonItem.customView startAnimating];	
	
	/*
	 UIImage *splash = [self getSlideImage];
	 splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 480)];
	 splashView.image = splash;
	 splashView.backgroundColor = [UIColor blackColor];
	 [theWebView addSubview:splashView];
	 */
	
	if (useRequest == NO) {
		//navItem.title = link.text;
		titleLabel.text = link.text;
		
		// to register localhost name		
		
		NSString *url = [local_host_prefix stringByAppendingString:link.url];
		if (realURL)
			[realURL release];
		
		realURL = [[NSURL alloc] initWithString:link.url];
		TRACE("%s: %s, %d\n", __func__, [url UTF8String], localServerStarted);
		
		[theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];	
		//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"file:///var/folders/Uv/UvZ97-wrGH8OcAyNxLfLOU+++TI/-Tmp-/cache/newsrss.bbc.co.uk/1010012844.stm"]];
	}
	//else {
	//	[theWebView loadRequest:request];	
	//}
	[theIndexPath release];
	[webLink release];
}

- (void)resetLink
{
	theIndexPath = nil;
	webLink = nil;
}

- (void)removeSplashView
{
	/*
	[splashView removeFromSuperview];
	[splashView.image release];
	[splashView release];
	 */
}

- (UIImage*)getSlideImage
{
	static int next = 0;
	
	next = ++next % 10;
	
	NSString *slide = [[NSString alloc] initWithFormat:@"slide%d.png", next];
	//NSString* imagePath=[[NSBundle mainBundle] pathForResource:slide ofType:@"png"]; 
	//UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
	UIImage *image = [UIImage imageNamed:slide];
	
	//TRACE("%s, %s\n", __func__, [imagePath UTF8String]);
	[slide release];
	//[imagePath release];
	return image;
}

- (void)stopProgressIndicator
{
	UINavigationItem *navItem = self.navigationItem;
	UIActivityIndicatorView *progView = (UIActivityIndicatorView *)navItem.rightBarButtonItem.customView;
	[progView stopAnimating];
	progView.hidden = YES;

	TRACE("%s\n", __func__);
}

/* Funny, but the definition has to be like the other one, not like this. 
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigatonType:(UIWebViewNavigationType)navigationType
{
	TRACE("%s:\n", __func__);
	
	[[UIApplication sharedApplication] openURL:[webView.request URL]];
	
	return YES;
}
*/
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	NSString *host = [url host];
	NSString *relative = [url relativePath];
	BOOL shouldStart = NO;
	
	TRACE("%s: host: %s, relative: %s\n", __func__, [host UTF8String], [relative UTF8String]);

	if (host == nil)
		return YES;
	
	if ([host compare:@"localhost"] == NSOrderedSame) {
		if ([relative hasPrefix:@"/http://"]) {
			// This is our local request
			shouldStart = YES;
		}
		//http://localhost:9000/2/hi/asia-pacific/default.stm
		else {
			// need to know real host
			NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:[realURL host] path:relative];
			//NSURL *realURL = [[NSURL alloc] initWithString:relative relativeToURL:hostURL];
			// TODO: disable this for now.
			//Configuration *config = [Configuration sharedConfigurationInstance];
			//[config saveURLForNextTime:[realURL absoluteString]];
			[[UIApplication sharedApplication] openURL:url];
			[url release];
		}
	}
	else {
		// TODO: disable this for now.
		Configuration *config = [Configuration sharedConfigurationInstance];
		[config saveURLForNextTime:[realURL absoluteString]];
		[[UIApplication sharedApplication] openURL:url];
		TRACE("%s, disabled.\n", __func__);
	}

	return shouldStart;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	UINavigationItem *navItem = self.navigationItem;
	
	UIActivityIndicatorView *progView = (UIActivityIndicatorView *)navItem.rightBarButtonItem.customView;
	[progView startAnimating];
	progView.hidden = NO;
	TRACE("%s\n", __func__);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	/*
	if (requireToStop == YES) {
		TRACE("%s, page should be reloaded.\n", __func__);
		requireToStop = NO;
		[self loadWeb];
		return;
	}*/
	
	[self stopProgressIndicator];
	TRACE("%s, %s\n", __func__, [[[webView.request URL] absoluteString] UTF8String]);
	
	// signal to do something
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	service.changeToLocalServerMode = NO;
	[service.doSomething broadcast];
	[self release];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	if (requireToStop == YES) {
		requireToStop = NO;
		[self release];
		return;
	}

	[self stopProgressIndicator];
	
	//TRACE("%s, %s\n", __func__, [host UTF8String]);
	
	// report the error inside the webview
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='black'>%@<br></font></center></html>",
							 description];
	[theWebView loadHTMLString:errorString baseURL:nil];
	[self release];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// TODO: Is this really good thing to do???
	if (theWebView.loading == YES) {
		requireToStop = YES;

		[theWebView stopLoading];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	//NSLog(@"%s", __func__);
	return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[realURL release];
    [super dealloc];
}


@end
