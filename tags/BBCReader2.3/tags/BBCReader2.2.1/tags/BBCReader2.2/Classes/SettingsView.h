//
//  SettingsView.h
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArticleStorage;
@class WebCacheService;
@class NetworkService;

@interface SettingsView : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
	IBOutlet UITableView	*myTableView;
	UIProgressView			*progressBar;
	UISwitch				*switchCtl;
	
	@private
	ArticleStorage			*storage;
	WebCacheService			*cacheService;
	NetworkService			*networkService;
	float                   downloadProgress;
	//NSDateFormatter			*formatter;
}

@property (nonatomic, retain) UITableView *myTableView;
@property (nonatomic, retain) UISwitch *switchCtl;

- (IBAction)cleanCache:(id)sender; 
- (void)create_UIProgressView;
- (void)create_UISwitch;
- (void)switchAction:(id)sender;

@end
