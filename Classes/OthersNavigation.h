//
//  OthersNavigation.h
//  NYTReader
//
//  Created by Jae Han on 8/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OthersNavigation : UINavigationController <UINavigationControllerDelegate> {
	BOOL didWebViewShown;
	NSAutoreleasePool *pool;
}

@property (nonatomic, assign) BOOL didWebViewShown;


@end
