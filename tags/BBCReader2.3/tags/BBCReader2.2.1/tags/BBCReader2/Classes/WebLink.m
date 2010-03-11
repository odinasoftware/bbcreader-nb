//
//  WebLink.m
//  NYTReader
//
//  Created by Jae Han on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "WebLink.h"


@implementation WebLink


@synthesize text;
@synthesize url;
@synthesize description;
@synthesize imageLink;
@synthesize isAvailable;

-(id) init {
	if (self = [super init]) {
		//text = [[NSString alloc] init];
		//url = [[NSString alloc] init];
		imageLink = nil;
		url = nil;
		isAvailable = NO;
	}
	
	return self;
}

- (void) dealloc 
{
	[text release];
	[url release];
	[description release];
	[imageLink release];
	[super dealloc];
}

@end

