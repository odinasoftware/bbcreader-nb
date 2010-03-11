//
//  WebHistoryNavigation.h
//  NYTReader
//
//  Created by Jae Han on 11/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebHistoryNavigation : UINavigationController {
	BOOL didWebViewShown;
	NSAutoreleasePool *pool;
}

@property (nonatomic, assign) BOOL didWebViewShown;

@end
