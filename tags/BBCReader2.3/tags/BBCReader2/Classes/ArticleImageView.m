//
//  ArticleImageView.m
//  NYTReader
//
//  Created by Jae Han on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ArticleImageView.h"
#import "ArticleStorage.h"
#import	"WebLink.h"

#define HORIZ_SWIPE_DRAG_MIN 12 
#define VERT_SWIPE_DRAG_MAX 4 

@implementation ArticleImageView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
    [super dealloc];
}


@end
