//
//  ArticleScrollView.h
//  NYTReader
//
//  Created by Jae Han on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {TOUCHES_NONE, TOUCHES_BEGAN, TOUCHES_MOVED, TOUCHES_END, TOUCHES_TAB, TOUCHES_DRAG} touches_status_t;

@interface ArticleScrollView : UIScrollView {
	@private
	touches_status_t			touchesStatus;
	//NSTimeInterval				tabTimeStamp;
}

@end
