//
//  ScrollViewController.h
//  NYTReader
//
//  Created by Jae Han on 10/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArticleScrollView;
@class ImageViewController;
@class WebLink;
@class ArticleStorage;

@interface PageViewControllerPointer : NSObject
{
	ImageViewController *controller;
	NSInteger			page;
	//WebLink				*link;
}

@property (nonatomic, retain) ImageViewController *controller;
@property (nonatomic, assign) NSInteger page;
//@property (nonatomic, retain) WebLink *link;

- (id)initWithPage:(NSInteger)num;

@end


@interface ScrollViewController : UIViewController <UIScrollViewDelegate> {
	IBOutlet ArticleScrollView	*scrollView;
	//IBOutlet UIToolbar			*toolBar;
	//IBOutlet UINavigationBar	*navigationBar;
	
	@private
	NSArray						*controllerArray;
	NSInteger					currentArrayPointer;
	NSInteger					currentPage;
	UIButton					*flipIndicatorButton;
	BOOL						frontViewIsVisible;
	WebLink						*currentWebLink;
	NSInteger					currentSelectedPage;
	UIBarButtonItem				*playBarButton, *stopBarButton;
	NSTimer						*slideShowTimer;
	BOOL						isSlideShowRunning;
	ImageViewController			*currentSlideImageController;
	NSInteger					numberOfPages;
	ArticleStorage				*storage;
}

@property (nonatomic, retain) ArticleScrollView *scrollView;
@property (nonatomic, retain) NSArray *controllerArray;

- (void)playSlideShow:(id)sender;
- (void)stopSlideShow:(id)sender;

- (WebLink*)loadImageView:(NSInteger)page;
- (void)addToControllerArray:(ImageViewController*)controller withPage:(NSInteger)page forLink:(WebLink*)link;
- (void)cleanController:(NSInteger)page;
- (void)showImageControls:(id)object;
- (void)updateImage;

@end
