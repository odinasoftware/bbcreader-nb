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
#import "GeoSession.h"
#import "FacebookConnect.h"

#define IMAGE_ATTACHMENT_FILENAME		@"BBCReader_picture_attachment.jpg"
#define WEB_VIEW_TAG 10
#define kCustomButtonHeight		30.0

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
		self.webLink = link;
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
	progressView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	progressView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
									 UIViewAutoresizingFlexibleRightMargin |
									 UIViewAutoresizingFlexibleTopMargin |
									 UIViewAutoresizingFlexibleBottomMargin);
	
	UINavigationItem *navItem = self.navigationItem;
	buttonItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];
	buttonItem.style = UIBarButtonItemStyleBordered;
	buttonItem.target = self;
	buttonItem.action = @selector(stopProgress:);
	navItem.rightBarButtonItem = buttonItem;
	
	//[progressView release];
	//[buttonItem release];
	
	if ([navItem.rightBarButtonItem.customView isKindOfClass:[UIActivityIndicatorView class]]) {
		[(UIActivityIndicatorView *)navItem.rightBarButtonItem.customView startAnimating];	
	}
	
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

- (void)stopProgress:(id)sender
{
	[self stopLoading];
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

#pragma mark MAIL CONTROLLER delegate

- (void)syncWithMail
{
	
	if ([MFMailComposeViewController canSendMail] == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail is not configured" message:@"Please check your Mail setting." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else {
		
		MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
		mailController.mailComposeDelegate = self;
				
		
		if (self.webLink.text)
			[mailController setSubject:self.webLink.text];
		
		if (self.webLink.description) {
			// When only text is available.
			
			[mailController setMessageBody:self.webLink.description isHTML:NO];
		}
		
		NSString *body = [[NSString alloc] initWithFormat:@"<HTML><BODY><p>%@</p><h6><p><a href='%@'>%@</a></p></h6></BODY></HTML>", 
						  self.webLink.description, self.webLink.url, @"Go to BBC to read the original article."];
		[mailController setMessageBody:body isHTML:YES];
		[body release];
		
		
		NSString *pictureLink = self.webLink.imageLink;
		if (pictureLink) {
			NSData *data = [[NSData alloc] initWithContentsOfFile:getActualPath(pictureLink)];
			[mailController addAttachmentData:data mimeType:@"image/jpeg" fileName:IMAGE_ATTACHMENT_FILENAME];
			TRACE("%s, attachment: %s, size: %d\n", __func__, [pictureLink UTF8String], [data length]);
			[data release];
		}
				
		[self presentModalViewController:mailController animated:YES];
		[mailController release];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
			
			break;
		case MFMailComposeResultSaved:
			
			break;
		case MFMailComposeResultSent:
			
			break;
		case MFMailComposeResultFailed:
			
			break;
		default:
			
			break;
	}
	TRACE("%s, result: %d\n", __func__, result);
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark Facebook Publish and Sync 

- (void)syncWithFacebook
{
	[[GeoSession getFBAgent] publishToFacebookForWebLink:self.webLink];
}

#pragma mark -
#pragma mark SEGMENT CONTROLLER
- (IBAction)segmentAction:(id)sender
{
	// The segmented control was clicked, handle it here 
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	TRACE("Segment clicked: %d\n", segmentedControl.selectedSegmentIndex);
	
	switch (segmentedControl.selectedSegmentIndex) {
		case 0:
			[self syncWithFacebook];
			break;
		case 1:
			[self syncWithMail];
			break;
		case 2:
		default:
			NSLog(@"%s, index error: %d", __func__, segmentedControl.selectedSegmentIndex);
	}
	
}
#pragma mark -
#pragma TWEET
- (void)syncWithTweet
{
    BOOL process = NO;
    
    if ([TWTweetComposeViewController canSendTweet] == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tweet alert" message:@"Cannot tweet! Please check your tweet setting in your iphone." 
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else {
        TWTweetComposeViewController *tweet = [[TWTweetComposeViewController alloc] init];
        process = [tweet setInitialText:self.webLink.text];
        process = [tweet addURL:[NSURL URLWithString:self.webLink.url]];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:getActualPath(self.webLink.imageLink)];
        process = [tweet addImage:image];
        tweet.completionHandler = ^(TWTweetComposeViewControllerResult result) {
            TRACE("%s, result: %d\n", __func__, result);
            
            if(result != TWTweetComposeViewControllerResultDone)
            {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Tweet error" message:@"Your Tweet was not posted!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
                [alertView release];
            }
            
            [self dismissModalViewControllerAnimated:YES];
        };
        
        [self presentModalViewController:tweet animated:YES];
        [tweet release];
    }
}
#pragma -
#pragma mark - UIActionSheetDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [self syncWithFacebook];
            break;
        case 2:
            if ([TWTweetComposeViewController class]) {
                [self syncWithTweet];
            }
            else {
                [self syncWithMail];
            }
            break;
        case 3:
            [self syncWithMail];
            break;
        case 0:
            break;
        default:
            break;
    }
}


#pragma mark -
- (void)chooseActions:(id)sender
{
    UIAlertView *alert = nil;
    
    if ([TWTweetComposeViewController class]) {
        alert = [[UIAlertView alloc] initWithTitle:@"Sync Article" 
                                                    message:@""
                                                   delegate:self 
                                          cancelButtonTitle:@"Cancel" 
                                          otherButtonTitles:@"Facebook", @"Tweet", @"Send mail", nil];
    }
    else {
        alert = [[UIAlertView alloc] initWithTitle:@"Sync Article" 
                                           message:@""
                                          delegate:self 
                                 cancelButtonTitle:@"Cancel" 
                                 otherButtonTitles:@"Facebook", @"Send mail", nil];
    }
	[alert show];
	[alert release];

}

- (void)stopProgressIndicator
{
	UINavigationItem *navItem = self.navigationItem;
	
	if ([navItem.rightBarButtonItem.customView isKindOfClass:[UIActivityIndicatorView class]]) {
		UIActivityIndicatorView *progView = (UIActivityIndicatorView *)navItem.rightBarButtonItem.customView;
		
	
		[progView stopAnimating];
		progView.hidden = YES;
	}
	
    /*
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"facebook.png"],
											 [UIImage imageNamed:@"mail1.png"],
											 nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
    */
    
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                          target:self 
                                                                          action:@selector(chooseActions:)];
	//UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:item];
    
    //[segmentedControl release];
    
	self.navigationItem.rightBarButtonItem = item;
    [item release];
    //[segmentBarItem release];
	

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
	
	if ([navItem.rightBarButtonItem.customView isKindOfClass:[UIActivityIndicatorView class]]) {
		UIActivityIndicatorView *progView = (UIActivityIndicatorView *)navItem.rightBarButtonItem.customView;
		[progView startAnimating];
		progView.hidden = NO;
	}
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
	[self stopProgressIndicator];
	
	//TRACE("%s, %s\n", __func__, [host UTF8String]);
	NSLog(@"%s, %@", __func__, [error localizedDescription]);
	// report the error inside the webview
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='black'>%@<br></font></center></html>",
							 description];
	[theWebView loadHTMLString:errorString baseURL:nil];

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
	[webLink release];
	[realURL release];
    [super dealloc];
}


@end
