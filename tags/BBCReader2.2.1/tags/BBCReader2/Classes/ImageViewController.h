//
//  FirstViewController.h
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArticleImageView;
@class WebLink;

@interface ImageViewController : UIViewController {
	IBOutlet ArticleImageView	*articleImageView;
	IBOutlet UILabel			*articleDescription;
	IBOutlet UILabel			*articleTitle;
	WebLink						*webLink;
	
	@private
	NSInteger					pageNum;
}

@property (nonatomic, retain) WebLink *webLink;

- (id)initWithNibName:(NSString *)nibNameOrNil withPage:(NSInteger)page;

- (void)showPrevImage;
- (void)showNextImage;
- (void)showNextImage:(NSTimer*)timer;
- (void)reDrawWithPage:(NSInteger)page;

@end
