//
//  ArticleTableView.h
//  NYTReader
//
//  Created by Jae Han on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArticleStorage;

@interface ArticleTableView : UITableView {
	@private
	CGPoint startTouchPosition;
}

@end
