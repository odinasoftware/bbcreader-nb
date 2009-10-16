//
//  TableCellView.m
//  NYTReader
//
//  Created by Jae Han on 9/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TableCellView.h"


@implementation TableCellView

- (void)setImageLink:(NSString*)link
{
	imageLink = link;
}

- (BOOL)compareImageLink:(NSString*)link
{
	return ([imageLink compare:link]==NSOrderedSame?YES:NO);
}

@end
