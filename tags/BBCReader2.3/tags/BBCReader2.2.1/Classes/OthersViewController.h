//
//  OthersViewController.h
//  NYTReader
//
//  Created by Jae Han on 8/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OthersViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView *theTableView;
}

//@property (nonatomic, retain) UITableView *theTableView;

@end
