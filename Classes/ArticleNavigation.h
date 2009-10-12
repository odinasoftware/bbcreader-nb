//
//  ArticleNavigation.h
//  NYTReader
//
//  Created by Jae Han on 7/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArticleViewController;
@class WebViewController;

@interface ArticleNavigation : UINavigationController <UINavigationControllerDelegate> {
	//ArticleViewController *articleView;
	//ArticleViewController *secondView;
	//BOOL useSecondView;
	BOOL				didWebViewShown;
	
	@private
	int					prevSelection;
	UISegmentedControl  *theSegmentedControl;
	NSAutoreleasePool	*pool;
	//WebViewController	*myWebViewController;
}

@property (nonatomic, assign) BOOL didWebViewShown;

- (void)showPreviousFeed;
- (void)showWebView:(NSIndexPath*)indexPath;
- (void)updateSegmentText:(int)index;
- (void)updateSegmentTitles;
- (void)showWebViewWithRequest:(NSURLRequest*)request;

@end
