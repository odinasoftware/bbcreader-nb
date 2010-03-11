//
//  TableCellView.h
//  NYTReader
//
//  Created by Jae Han on 9/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TableCellView : UIImageView {
	@private
	NSString *imageLink;
}

- (void)setImageLink:(NSString*)link;
- (BOOL)compareImageLink:(NSString*)link;

@end
