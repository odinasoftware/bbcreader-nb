//
//  ArticleTableView.m
//  NYTReader
//
//  Created by Jae Han on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ArticleTableView.h"
#import "ArticleStorage.h"

#define HORIZ_SWIPE_DRAG_MIN 12 
#define VERT_SWIPE_DRAG_MAX 4 

@implementation ArticleTableView


- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		// Initialization code
		
	}
	return self;
}


- (void)dealloc {
	[super dealloc];
}


@end
