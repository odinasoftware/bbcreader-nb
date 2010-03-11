//
//  ThumbNailHolder.m
//  NYTReader
//
//  Created by Jae Han on 8/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "ThumbNailHolder.h"

static ThumbNailHolder *theSharedThumbnailHolder = nil;

@implementation thumb_nail_object_t

@synthesize orig_url;
@synthesize local_name;
@synthesize indexPath;

- (void)dealloc
{
	[orig_url release];
	[local_name release];
	[indexPath release];
	
	[super dealloc];
}
@end


@implementation ThumbNailHolder

@synthesize theThumbnailHolder;
@synthesize theCurrentIndex;

+(ThumbNailHolder*) sharedThumbNailHolderInstance 
{
	@synchronized(self) {
		if (theSharedThumbnailHolder == nil) {
			[[self alloc] init];
		}
	}
	return theSharedThumbnailHolder;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized(self) { 
		if (theSharedThumbnailHolder == nil) { 
			theSharedThumbnailHolder = [super allocWithZone:zone]; 
			return theSharedThumbnailHolder; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

+ (NSInteger)addThumbnail:(NSString*)orig_url withLocalName:(NSString*)local_name atIndexPath:(NSIndexPath*)indexPath
{
	NSInteger c = 0;
	ThumbNailHolder *storage = [ThumbNailHolder sharedThumbNailHolderInstance];
	if (storage == nil) {
		NSLog(@"%s, can't get the shared instance.", __func__);
		return -1;
	}
	
	@synchronized (storage) {
		thumb_nail_object_t *thumbnail = [[thumb_nail_object_t alloc] init];
		thumbnail.orig_url = orig_url;
		thumbnail.local_name = local_name;
		thumbnail.indexPath = indexPath;
		
		[storage.theThumbnailHolder addObject:(id)thumbnail];
		TRACE("*****> addThumbnail: %s\n", [orig_url UTF8String]);
		c = [storage.theThumbnailHolder count]-1;
	}
	
	return c;
}

+ (void)addThumbnail:(NSString*)orig_url withLocalName:(NSString*)local_name atIndexPath:(NSIndexPath*)indexPath withPrevIndex:(NSInteger)prev
{
	ThumbNailHolder *storage = [ThumbNailHolder sharedThumbNailHolderInstance];
	if (storage == nil) {
		NSLog(@"%s, can't get the shared instance.", __func__);
		return;
	}
	
	@synchronized (storage) {
		thumb_nail_object_t *thumbnail = [[thumb_nail_object_t alloc] init];
		thumbnail.orig_url = orig_url;
		thumbnail.local_name = local_name;
		thumbnail.indexPath = indexPath;
		
		//[storage.theThumbnailHolder addObject:(id)thumbnail];
		[storage.theThumbnailHolder replaceObjectAtIndex:prev withObject:thumbnail];
		TRACE("*****> addThumbnail: %s\n", [orig_url UTF8String]);
	}
	
}

+ (thumb_nail_object_t*)getThumbnail
{
	thumb_nail_object_t* thumbnail = nil;
	ThumbNailHolder *storage = [ThumbNailHolder sharedThumbNailHolderInstance];
	if (storage == nil) {
		NSLog(@"%s, can't get the shared instance.", __func__);
		return thumbnail;
	}
	
	@synchronized(storage) {
		if (storage.theCurrentIndex < [storage.theThumbnailHolder count]) {
			thumbnail = (thumb_nail_object_t*)[storage.theThumbnailHolder objectAtIndex:storage.theCurrentIndex];
			storage.theCurrentIndex = storage.theCurrentIndex + 1;
		}
	}
	
	return thumbnail;
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

- (id)init
{
	if ((self = [super init])) {
		theThumbnailHolder = [[NSMutableArray alloc] initWithCapacity:50];
		theCurrentIndex = 0;
	}
	return self;
}


+ (void)releaseThumbNails
{
	ThumbNailHolder *storage = [ThumbNailHolder sharedThumbNailHolderInstance];
	
	if (storage) {
		[storage.theThumbnailHolder removeAllObjects];
	}
	
	// TODO: Why it's crashing???
	// because i am releasing all entries above.
	//[storage.theThumbnailHolder release];
	
}
@end
