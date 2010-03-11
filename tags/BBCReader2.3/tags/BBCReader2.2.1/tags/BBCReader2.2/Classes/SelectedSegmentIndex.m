//
//  SelectedSegmentIndex.m
//  NYTReader
//
//  Created by Jae Han on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SelectedSegmentIndex.h"


@implementation SelectedSegmentIndex

@synthesize index;

- (id)initWithSegmentIndex:(NSInteger)segmentIndex
{
	if (self = [super init]) {
		index = segmentIndex;
	}
	
	return self;
}

@end
