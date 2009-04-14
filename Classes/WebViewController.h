//
//  WebViewController.h
//  NYTReader
//
//  Created by Jae Han on 9/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebLink;

@interface WebViewController : UIViewController <UIWebViewDelegate> {
	//IBOutlet UIWebView	*theWebView;
	//IBOutlet UIImageView *splashView;
	UIWebView	*theWebView;
	
	NSIndexPath	*theIndexPath;
	WebLink		*webLink;
	//NSURLRequest *request;
	
	@private
	//UIImageView *splashView;
	NSURL	    *realURL;
	BOOL		requireToStop;
	UILabel		*titleLabel;
	UIActivityIndicatorView *progressView;
	UIBarButtonItem *buttonItem;
	NSString	*description;
}

@property (nonatomic, retain) NSIndexPath *theIndexPath;
@property (nonatomic, retain) WebLink *webLink;
//@property (nonatomic, retain) NSURLRequest *request;

- (void)removeSplashView;
- (UIImage*)getSlideImage;
- (void)loadWeb;
- (BOOL)isLoadingPage;
- (void)stopLoading;
- (void)resetLink;

//- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigatonType:(UIWebViewNavigationType)navigationType;

@end
