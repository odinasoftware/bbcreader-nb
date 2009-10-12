//
//  NYTReaderAppDelegate.h
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebLink;
@class ReaderTabController;

@interface BBCReaderAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet ReaderTabController *tabBarController;
	
	@private
	BOOL reloadArticleData;
	BOOL showedNetworkError;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;

- (void)addNewArticle:(WebLink*)article;
- (void)setTitle:(NSString*)title;
- (void)showPreviousFeed:(id)object;
- (void)selectArticleAtIndexPath:(NSIndexPath*)indexPath;
- (void)showPrevArticleImage:(WebLink*)article;
- (void)showNextArticleImage:(WebLink*)article;
//- (void)openWebViewAtIndex:(NSIndexPath*)indexPath;
- (void)reloadArticleWithIndex:(id)index;
- (void)showImageControls:(id)object;
//- (void)openWebViewWithLink:(WebLink*)link;
- (void)updateImageLink:(id)object;
- (void)displayDiskWarning:(id)object;
- (void)updateSegmentTitles:(id)object;
- (void)showNetworkError:(id)object;
- (void)removeSplashView:(id)object;
//- (void)openWebViewWithRequest:(NSURLRequest*)request;
- (void)updateHistory:(id)object;
- (void)reachabilityChanged:(NSNotification *)note;
- (void)showOfflineModeWarning:(id)object;

@end
