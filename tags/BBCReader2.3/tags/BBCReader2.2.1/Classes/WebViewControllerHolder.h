//
//  WebViewControllerHolder.h
//  NYTReader
//
//  Created by Jae Han on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUMBER_OF_CONTROLLER	1

@class WebViewController;

@interface WebViewControllerHolder : NSObject {
	WebViewController *controllerArray[NUMBER_OF_CONTROLLER];
	int		index;
	//WebViewController *controller;
}

+ (WebViewControllerHolder*)sharedWebViewControllerInstance;
+ (WebViewController*)getWebViewController:(BOOL*)needLoad;
- (WebViewController*)getWebViewInstance:(BOOL*)needLoad;

@end
