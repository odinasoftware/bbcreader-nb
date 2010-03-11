//
//  SelectedSegmentIndex.h
//  NYTReader
//
//  Created by Jae Han on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SelectedSegmentIndex : NSObject {
	NSInteger index;
}

@property (assign) NSInteger index;

- (id)initWithSegmentIndex:(NSInteger)segmentIndex;

@end
