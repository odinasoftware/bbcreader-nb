//
//  WebLink.h
//  NYTReader
//
//  Created by Jae Han on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebLink : NSObject {
	NSString *text;
	NSString *url;
	NSString *description;
	NSString *imageLink;
	BOOL      isAvailable;
}

@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) NSString* url;
@property (nonatomic, retain) NSString* description;
@property (nonatomic, retain) NSString* imageLink;
@property (nonatomic, assign) BOOL isAvailable;

@end
