//
//  ImageNavigation.h
//  NYTReader
//
//  Created by Jae Han on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebLink;

@interface ImageNavigation : UINavigationController <UINavigationControllerDelegate> {
	BOOL didWebViewShown;
	NSAutoreleasePool *pool;
}

@property (assign) BOOL didWebViewShown;

- (void)showWebView:(WebLink*)link;

@end
