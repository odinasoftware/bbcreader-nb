//
//  WebCacheService.h
//  NYTReader
//
//  Created by Jae Han on 7/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "MReader_Defs.h"

#define FEED_DIR_COMPONENT @"feed"
#define HTML_DIR_COMPONENT @"html"
#define THUMB_DIR_COMPONENT @"thumb"
#define DEFAULT_DIR_COMPONENT @"default"

@class CacheEntry;
@class ParserHandler;
@class EmbeddedObjects;
@class embedded_object_t;

@interface CacheObject : NSObject {
	NSString			*url;
	cache_category_t	category;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) cache_category_t category;

@end


@interface WebCacheService : NSObject {
	NSInteger		numberOfCSSs;
	
	@private
	NSString		*rootLocation;
	NSString		*indexLocation;
	NSFileManager	*fileManager;
	
	NSString		*hostForCacheObjects;
	NSMutableDictionary *cacheObjects;
	EmbeddedObjects	*theEmbeddedObjects;
	NSMutableDictionary	*garbageDictionary;
	NSMutableDictionary *thumbDictionary;
	NSMutableDictionary *cssDictionary;
	
	// File descriptor for index files
	int				feedDescriptor;
	int				htmlDescriptor;
	int				thumbDescriptor;
	int				otherDescriptor;
	NSObject		*dummy;
	NSArray			*fileBufferManager;
	int				currentFileBufferIndex;
	int				nGarbage;
	int				nThumbGarbage;
}

@property (nonatomic, retain) NSString* rootLocation;
@property (nonatomic, retain) NSString* indexLocation;
@property (nonatomic, retain) NSString* hostForCacheObjects;
@property (nonatomic, retain) NSMutableDictionary* cssDictionary;
@property (nonatomic, assign) NSInteger numberOfCSSs;

+ (WebCacheService*) sharedWebCacheServiceInstance;
+ (void)releaseCacheObject;
+ (void)removeThisFromGarbage:(NSString*)file;

//- (void)removeAllItems;
//- (NSString*)getUniqueFileName:(NSURL*)url;

- (NSString*)getHTMLPathWithHost:(NSString*)host;
- (CacheEntry*)getCachedFileName:(NSURL*)url withCategory:(cache_category_t)category isAvailable:(BOOL*)available;
- (void)saveToCache:(CacheEntry*)entry withData:(NSData*)data;
- (NSMutableArray*) getUrlForIndex:(NSString*)file forCategory:(cache_category_t)category;
- (NSString*)getLocalName:(NSString*)url withHandler:(ParserHandler*)handler;
- (void)initCacheObjects:(NSString*)host;
//- (NSString*)getEmbeddedStorageName;
- (void)prepareEmbeddedObjectsStorage:(CacheEntry*)cacheEntry;
- (void)saveEmbeddedObjectsToStorage;
- (void)flushCacheEntry:(CacheEntry*)entry;
- (void)releaseCacheEntries;
- (void)moveTheCurrentEmbeddedObjectToFront;
- (void)postProcessing:(CacheEntry*)cacheEntry atIndex:(NSIndexPath*)indexPath;
- (BOOL)hasThisFile:(NSString*)file atIndex:(NSIndexPath*)indexPath;
//- (NSString*)getLocalName:(NSString*)url;
- (void)saveResponseHeader:(NSData*)response withLocalFile:(NSString*)file;
- (BOOL)doesCacheExist:(NSString*)file;
- (NSData*)readFromFile:(NSString*)file;
- (NSData*)readFromFileDescriptor:(int)fd withBlockSize:(int)block_size;
- (NSString*)getIndexDescriptorFromCacheFile:(NSString*)file;
- (NSString*)getLocalName:(NSString*)url withCategory:(cache_category_t)category withHandler:(ParserHandler*)handler;
//- (void)loadCacheObjectWithIndexFile:(NSString*)indexFile;
- (NSArray*)getDummyObjecs:(NSInteger)count;
//- (int)getIndexDescriptorFrimCategory:(cache_category_t)category;
//- (void)addFileName:(NSString*)name toIndexCategory:(cache_category_t)category;
- (NSString*)checkCacheAndRegister:(NSString*)url withFile:(NSString**)localFile forIndexFile:(NSString**)indexName fromCategory:(cache_category_t)category isAvailable:(BOOL*)available isCollide:(BOOL*)collision;
- (NSInteger)loadCacheObjectsFromCategory:(cache_category_t)category;
- (BOOL)checkExpiration:(NSString*)file;
- (BOOL)doGarbageCollection;
- (void)addToCSSDictionary:(embedded_object_t*)object;
- (NSString*)getLocalFileNameFromURL:(NSString*)url;
- (NSData*)getNextFileBuffer;
- (BOOL)doGarbageCollectionForThumbnail;
- (void)removeThisFromGarbage:(NSString*)file;
- (BOOL)unlinkThisThumbFile:(NSString*)file;
- (BOOL)doGarbageCollectionForThumbnail;
- (void)emptyCache;
- (BOOL)isCacheCreated;
- (NSString*)getThumbPathWithHost:(NSString*)host;
- (void)checkCacheObjects;

@end
