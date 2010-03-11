//
//  TableCellView.m
//  NYTReader
//
//  Created by Jae Han on 9/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TableCellView.h"


@implementation TableCellView

@synthesize imageLink;

//- (void)setImageLink:(NSString*)link
//{
//	self.imageLink = link;
//}

- (BOOL)compareImageLink:(NSString*)link
{
	return ([imageLink compare:link]==NSOrderedSame?YES:NO);
}

@end
