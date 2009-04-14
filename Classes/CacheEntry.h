//
//  CacheEntry.h
//  NYTReader
//
//  Created by Jae Han on 7/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CacheEntry : NSObject {
	NSString	*indexFile;
	NSString	*cacheFile;
	NSURL		*origURL;
}

@property (nonatomic, retain) NSString* indexFile;
@property (nonatomic, retain) NSString* cacheFile;
@property (nonatomic, retain) NSURL* origURL;

- (id)initWithIndex:(NSString*)indexed andCacheFile:(NSString*)cached andURL:(NSURL*)url;

@end
