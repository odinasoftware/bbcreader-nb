//
//  ArticleViewController.h
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {MAIN_ARTICLE_MODE, OTHER_ARTICLE_MODE} article_view_mode_t;

@interface ArticleViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
	IBOutlet UITableView		*theTableView;
	IBOutlet UIView				*statusView;
	IBOutlet UIButton					*infoButton;
	IBOutlet UIActivityIndicatorView	*activityIndicator;
	IBOutlet UILabel					*statusUpdate;
	IBOutlet UILabel					*lastUpdate;
	
	//IBOutlet UINavigationBar	*theNavigationBar;
	UIImage						*defaultBBCLogo;
	article_view_mode_t			viewMode;
	
	@private
	UIActivityIndicatorView *progressView;
	UILabel *message;
	BOOL						isThisOtherView;
	//NSDate	*lastUpdateDate;
}

@property (nonatomic, retain) UITableView* theTableView;
@property (nonatomic, assign) article_view_mode_t viewMode;
//@property (nonatomic, retain) NSDate *lastUpdateDate;
//@property (nonatomic, retain) UINavigationBar* theNavigationBar;

- (void)setToSegmentControl:(id)sender;
- (void)showNetworkError;
- (void)updateDownloadStatus;

@end
