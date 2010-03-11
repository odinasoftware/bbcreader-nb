//
//  CacheEntry.m
//  NYTReader
//
//  Created by Jae Han on 7/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CacheEntry.h"


@implementation CacheEntry

@synthesize indexFile;
@synthesize cacheFile;
@synthesize origURL;

- (id)init 
{
	if (self = [super init]) {
		indexFile = nil;
		cacheFile = nil;
		origURL = nil;
	}
	return self;
}

- (id)initWithIndex:(NSString*)indexed andCacheFile:(NSString*)cached andURL:(NSURL*)url
{
	if (self = [super init]) {
		indexFile = indexed;
		cacheFile = cached;
		origURL = url;
	}
	return self;
}

- (void)dealloc 
{
	/* Retain does not really hold it if it is owned by cocoa.
	 * Don't release it here. it will crash pool.
	 */
	//[indexFile release]; 
	//[cacheFile release]; 
	[origURL release];

	[super dealloc];
}

@end
