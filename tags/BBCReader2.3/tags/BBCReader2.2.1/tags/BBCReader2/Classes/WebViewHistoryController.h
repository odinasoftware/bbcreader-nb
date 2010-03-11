//
//  WebViewHistoryController.h
//  NYTReader
//
//  Created by Jae Han on 11/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Configuration;

@interface WebViewHistoryController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView		*theTableView;
	//IBOutlet UINavigationBar	*theNavigationBar;
	UIImage						*defaultBBCLogo;
	
@private
	Configuration				*configuration;
}

@property (nonatomic, retain) UITableView* theTableView;

- (void)clearHistory:(id)sender;

@end
