//
//  ArticleDelegate.h
//  NYTReader
//
//  Created by Jae Han on 7/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ArticleDelegate : NSObject {
	IBOutlet UINavigationController *navigationController;
}

@property (nonatomic, retain) UINavigationController* navigationController;

@end
