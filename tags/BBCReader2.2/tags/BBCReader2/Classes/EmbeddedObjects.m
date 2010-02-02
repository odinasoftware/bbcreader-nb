//
//  EmbeddedObjects.m
//  NYTReader
//
//  Created by Jae Han on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include <fcntl.h>
#import "EmbeddedObjects.h"
#import "WebCacheService.h"

const char BLANK = ' ';
const char NEWLINE = '\n';

void writeToIndexFile(const char *file_name, const char *url, BOOL collision) 
{
	int fd = open(file_name, O_RDWR | O_APPEND);
	// if it is already there, then just appening url to the file, 
	// this the hash collision case.
	if ((fd != -1) && (collision == NO)) {
		// refering the one existing, just return.
		close(fd);
		return;
	}
	if (fd == -1) {
		// otherwise create a new file
		fd = open(file_name, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
		if (fd == -1) {
			NSLog(@"%s: %s, %s", __func__, file_name, strerror(errno));
			return;
		}
		
	}
	
	write(fd, (const void*)url, strlen(url));
	write(fd, (const void*)&NEWLINE, 1);
	close(fd);
}

@implementation embedded_object_t

@synthesize orig_url;
@synthesize local_name;
@synthesize index_name;
@synthesize collision;

- (void)dealloc
{
	[orig_url release];
	[local_name release];
	[index_name release];
	collision = NO;
	
	[super dealloc];
}

@end

@implementation EmbeddedObjects

- (id)initWithName:(NSString*)name {
	if ((self = [super init])) {
		embeddedObjects = [[NSMutableArray alloc] initWithCapacity:50];
		rootName = name;
		cacheService = [WebCacheService sharedWebCacheServiceInstance];
	}
	return self;
}

/* addEmbeddedObject
 *   orig_url: original url for this object
 *   local_name: cache file name for this object
 *   index_name: cache index name for representing this object in cache
 *   collision: this object's index has been collided in hash, and should be mindful with this.
 *
 */
- (void)addEmbeddedObject:(NSString*)orig_url withLocalName:(NSString*)local_name withIndexName:(NSString*)index_name wasCollided:(BOOL)collsion
{
	if (orig_url == nil) {
		NSLog(@"url is null");
	}
	embedded_object_t *object = [[embedded_object_t alloc] init];
	object.orig_url = orig_url;
	object.local_name = local_name;
	object.index_name = index_name;
	object.collision = collsion;
	[embeddedObjects addObject:(id)object];
}

- (void)moveTheCurrentEmbeddedObjectToFront
{
	if ([embeddedObjects count] > 1)
		[embeddedObjects exchangeObjectAtIndex:0 withObjectAtIndex:[embeddedObjects count]-1];
}

/* SaveToStorage
 *	Save the current list of embedded objects to the storage.
 *  Need to get the file name from "rootName" and save to the file.
 *
 * Requirement for caching
 * -----------------------
 *  Cache needs to read this file first to see if there needs to download any embedded objects.
 *  Before downloading them, it shall check the file is existed or not. 
 *
 */
- (void)saveToStorage
{	
	//NSFileManager* manager = [NSFileManager defaultManager];
	//[manager createFileAtPath:rootName contents:nil attributes:nil];
	int fd = open([rootName UTF8String], O_RDWR | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (fd == -1) {
		NSLog(@"%s: %@, %s", __func__, rootName, strerror(errno));
		return;
	}
	
	// TODO: Write orig_url and local name data to the file.
	int i = 0;
	for (i=0; i<[embeddedObjects count]; ++i) {
		embedded_object_t* object = [embeddedObjects objectAtIndex:i];
		if (object.orig_url != nil) {
			write(fd, [object.orig_url UTF8String], [object.orig_url length]);
			write(fd, (const void*) &BLANK, 1);
			write(fd, [object.local_name UTF8String], [object.local_name length]);
			write(fd, (const void*) &NEWLINE, 1);
			//[file writeData:[object.orig_url dataUsingEncoding:NSUTF8StringEncoding]];
			//[file writeData:[object.local_name dataUsingEncoding:NSUTF8StringEncoding]];
			writeToIndexFile([object.index_name UTF8String], [object.orig_url UTF8String], object.collision);
			if ([[object.local_name pathExtension] compare:@"css"] == NSOrderedSame) {
				// Add this to css dictionary
				[cacheService addToCSSDictionary:object];
			}
		}
		
		//[object.orig_url release];
		//[object.local_name release];
		//[object.index_name release];
		[object release];  // <--- to release alloc
	}
	
	//[file closeFile];
	close(fd);
}

- (void)dealloc
{
	/*
	int i =0;
	for (i=0; i<[embeddedObjects count]; ++i) {
		embedded_object_t *object = (embedded_object_t*) [embeddedObjects objectAtIndex:i];
		//[object.orig_url release];
		//[object.local_name release];
		[object release]; // <--- to release retain by array
	}
	 */
	[embeddedObjects release];
	[super dealloc];
}
@end
