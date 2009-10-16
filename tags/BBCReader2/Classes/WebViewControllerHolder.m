//
//  WebViewControllerHolder.m
//  NYTReader
//
//  Created by Jae Han on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "WebViewControllerHolder.h"
#import "WebViewController.h"

static WebViewControllerHolder *sharedWebViewControllerStorage = nil;

@implementation WebViewControllerHolder

+ (WebViewControllerHolder*) sharedWebViewControllerInstance
{
	@synchronized(self) {
		if (sharedWebViewControllerStorage == nil) {
			[[self alloc] init];
		}
	}
	return sharedWebViewControllerStorage;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized(self) { 
		if (sharedWebViewControllerStorage == nil) { 
			sharedWebViewControllerStorage = [super allocWithZone:zone]; 
			return sharedWebViewControllerStorage; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

+ (WebViewController*)getWebViewController:(BOOL*)needLoad
{
	WebViewControllerHolder *holder = [WebViewControllerHolder sharedWebViewControllerInstance];
	
	return [holder getWebViewInstance:needLoad];
}

- (WebViewController*)getWebViewInstance:(BOOL*)needLoad
{	
	int i = 0;
	WebViewController **controller = nil;
	
	do {
		index = (index + 1) % NUMBER_OF_CONTROLLER;
		controller = &controllerArray[index];
		
		if (*controller == nil) {
			*controller = [[WebViewController alloc] init];
			*needLoad = NO;
			break;
		}/*
		else if ([(*controller) isLoadingPage] == YES) {
			// TODO: causing deadlock, why???
			//[(*controller) stopLoading];
			// page is loading, use different controller
			continue;
		}
		 */
		else {
			[(*controller) resetLink];
			//if ((*controller).theIndexPath != nil)
			//	(*controller).theIndexPath = nil;
			//if ((*controller).webLink != nil)
			//	(*controller).webLink = nil;
			
			*needLoad = YES;
			break;
		}
		i++;
		
	} while (i < NUMBER_OF_CONTROLLER);
	
	if (*controller == nil) {
		NSLog(@"%s, Can't get free webviewcontroller.", __func__);
	}
	
	return *controller;
}

- (id)init 
{
	if ((self = [super init])) {
		for (int i=0; i<NUMBER_OF_CONTROLLER; ++i) {
			controllerArray[i] = nil;
		}
		
		index = -1;
		//controller = nil;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{ 
	return self; 
} 
- (id)retain 
{ 
	return self; 
} 
- (unsigned)retainCount 
{ 
	return UINT_MAX; //denotes an object that cannot be released 
} 
- (void)release 
{ 
	//do nothing 
} 
- (id)autorelease 
{ 
	return self; 
} 

@end
