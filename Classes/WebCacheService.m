//
//  WebCacheService.m
//  NYTReader
//
//  Created by Jae Han on 7/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
//#define _DEBUG
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#import "MReader_Defs.h"
#import "CacheEntry.h"
#import "WebCacheService.h"
#import "ParserHandler.h"
#import "EmbeddedObjects.h"
#import "ThumbNailHolder.h"
#import "ArticleStorage.h"
#import "Configuration.h"

#define MAX_FILE_BUFFERS    10
#define MAX_LINE_LEN		512
#define MAX_EXT				10
#define BLOCK_SIZE			4096
#define CARRIAGE_RETURN		0x0d
#define LINE_FEED			0x0a
#define GARBAGE_INTERVAL	86400 // ticks for a day 
#define CSS_GARBAGE_INTERVAL 604800 // ticks for week

typedef enum {SEARCH_PROTOCOL_TYPE, SEARCH_GET_RESULT, BEGIN_NEW_LINE, SEARCH_FIELD, SEARCH_VALUE, SKIP_TO_NEXT_LINE, BODY_FOUND} response_parser_mode_t;

static const unsigned char BLANK = ' ';
static const unsigned char NEWLINE = '\n';
static NSString *EMBEDDED_FILE_EXT = @".emb.txt";
static WebCacheService* sharedWebCacheService = nil;
static unsigned char temp_storage[MAX_LINE_LEN];
static unsigned char temp_file_storage[BLOCK_SIZE];
static NSString *EXPIRES_FIELD = @"Expires";

/*
static const NSString* FEED_INDEX_FILE_NAME = @"feed.mreader";
static const NSString* HTML_INDEX_FILE_NAME = @"html.mreader";
static const NSString* THUMB_INDEX_FILE_NAME = @"thumb.mreader";
static const NSString* OTHER_INDEX_FILE_NAME = @"other.mreader";
 */
//static const NSString *local_host_prefix = @"http://localhost:9000";

NSString *getActualPath(NSString* sourcePath)
{
	NSString *file = nil;
#define USE_DOCUMENT_DIR	1
	
#if USE_DOCUMENT_DIR
	NSArray *paths;
	NSError *error;
	
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)
    {
        // only copying one file
        file = [[paths objectAtIndex:0] stringByAppendingPathComponent:sourcePath];
    }
	else {
		// create a suitable NSError object to return in outError
		NSLog(@"%s, %@", __func__, [error localizedDescription]);
	}
#else
	file = [NSTemporaryDirectory() stringByAppendingPathComponent:sourcePath];
#endif
	
    return file;
}

static int scanTwoStrings(unsigned char *buffer, int read, NSString **first, NSString **second)
{
	int i = 0;
	int s = 0;
	int e = 0;
	for (i=0; i<read; ++i) {
		if (buffer[i] == BLANK) {
			// found separator
			s = i;
		}
		else if (buffer[i] == NEWLINE) {
			// found two string.
			if ((i-s) < 20) {
				// This does not have valid file and url. 
				return i+1;
			}
			e = i;
			*first = [[NSString alloc] initWithBytes:(const void*)&buffer[0] length:s encoding:NSUTF8StringEncoding];
			*second = [[NSString alloc] initWithBytes:&buffer[s+1] length:e-s-1 encoding:NSUTF8StringEncoding];
			return i+1;
		}		
	}
	return i;
}

unichar* getExtensionFromURL(NSString *url) {
	// find extension for the local name
	int i = 0;
	unichar c;
	unichar *extension = nil; 

	int len = [url length];
	int end = len;
	for (i=[url length]-1; i>=0; --i) {
		c = [url characterAtIndex:i];
		if (c == '.') {
			if ((([url length] - end) >= MAX_EXT) || end-i > 4) {
				//NSLog(@"unknown extension detected.");
				return nil;
			}
			extension = (unichar*) malloc(sizeof(unichar)*10);
			[url getCharacters:extension range:NSMakeRange(i, end-i)];
			extension[end-i] = '\0';
			break;
		}
		else if (c == '?') {
			end = i;
		} 
		else if (c == '&') {
			end = i;
		} 
		else if (c == ';') {
			end = i;
		}
		else if (c == '/') {
			i = -1;
			break;
		}
	}
	
	return extension;
}

BOOL isPicture(NSString* file)
{
	BOOL ret = NO;
	NSString *extension = [file pathExtension];
	if (([extension compare:@"jpg"] == 0) ||
		([extension compare:@"gif"] == 0) ||
		([extension compare:@"png"] == 0)) {
		ret = YES;
	}
	
	return ret;
}

NSString *getCategoryComponent(cache_category_t category)
{
	if (category == CACHE_FEED)
		return @"feed";
	else if (category == CACHE_HTML)
		return @"html";
	else if (category == CACHE_THUMB_NAIL)
		return @"thumb";

	return @"default";
}

BOOL copyToNewCategory(NSString *file, NSString* currentCategoryString, cache_category_t category)
{
	BOOL exists = NO;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	
	if ([manager fileExistsAtPath:getActualPath(file)] == YES) {
		// copy this to the new category.
		NSString *path = getActualPath(file);
		NSRange range = [path rangeOfString:currentCategoryString];
		NSString *new_file = [path stringByReplacingCharactersInRange:range withString:getCategoryComponent(category)];
		
		[manager copyItemAtPath:getActualPath(file) toPath:new_file error:&error];
		if (error != nil) {
			NSLog(@"%s, %@", __func__, error);
		}	
		exists = YES;
	}
	
	return exists;
}

void replaceToNewCategory(NSString** index, NSString **cache, NSString *currentCategoryString, cache_category_t category)
{
	NSRange range = [*index rangeOfString:currentCategoryString];
	*index = [*index stringByReplacingCharactersInRange:range withString:getCategoryComponent(category)];
	range = [*cache rangeOfString:currentCategoryString];
	*cache = [*cache stringByReplacingCharactersInRange:range withString:getCategoryComponent(category)];
}

BOOL canThisBeGarbage(NSString* file, time_t today, int interval)
{
	struct stat sb;
	
	if (stat([file UTF8String], &sb) < 0) {
		//NSLog(@"%s, %s", __func__, strerror(errno));
		return NO;
	}
		
	TRACE("----> %s, %d, today: %d\n", [file UTF8String], sb.st_atime, today);
	
	if (today > sb.st_atime + interval)
		return YES;
	
	return NO;
}

int OPEN(NSString* name, int flag)
{
	return open([getActualPath(name) UTF8String], flag);
}


@implementation CacheObject 

@synthesize url;
@synthesize category;

- (id)initWithEntry:(NSString*)orig_url forCategory:(cache_category_t)cache_category
{
	if (self = [super init]) {
		url = orig_url;
		category = cache_category;
	}
	
	return self;
}

- (void)dealloc
{
	// TODO: see if it leaks or not first. 
	//[url release];
	[super dealloc];
}

@end

@implementation WebCacheService

@synthesize rootLocation;
@synthesize indexLocation;
@synthesize hostForCacheObjects;
@synthesize cssDictionary;
@synthesize numberOfCSSs;

+ (WebCacheService*) sharedWebCacheServiceInstance
{
	@synchronized(self) {
		if (sharedWebCacheService == nil) {
			[[self alloc] init];
		}
	}
	return sharedWebCacheService;
}

+ (id)allocWithZone:(NSZone*)zone
{
	@synchronized(self) {
		if (sharedWebCacheService == nil) {
			sharedWebCacheService = [super allocWithZone:zone];
			return sharedWebCacheService;
		}
	}
	return nil;
}

+ (void)removeThisFromGarbage:(NSString*)file
{
	WebCacheService* service = [WebCacheService sharedWebCacheServiceInstance];
	
	[service removeThisFromGarbage:file];
}

- (id)init
{
	//NSString *tmp_loc;
	if (self = [super init]) {
		
		// TODO: Why should I do retain here???
		//tmp_loc = [[NSString alloc] initWithString:NSTemporaryDirectory()];
		//rootLocation = [[tmp_loc stringByAppendingPathComponent:@"/cache/"] retain];
		rootLocation = [[NSString stringWithString:@"/cache/"] retain];
		//[tmp_loc release];
		//tmp_loc = [[NSString alloc] initWithString:NSTemporaryDirectory()];
		//indexLocation = [[tmp_loc stringByAppendingPathComponent:@"/index/"] retain];
		indexLocation = [[NSString stringWithString:@"/index/"] retain];
		//[tmp_loc release];
		
		// Only when device needs to be cleaned
		//[self removeAllItems];
		
		fileManager = [NSFileManager defaultManager];
		
		cacheObjects = [[NSMutableDictionary alloc] initWithCapacity:100];
		hostForCacheObjects = nil;
		
		feedDescriptor = htmlDescriptor = thumbDescriptor = otherDescriptor = -1;
		garbageDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
		thumbDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
		dummy = [[NSObject alloc] init];
		cssDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
		numberOfCSSs = 0;
		currentFileBufferIndex = -1;
		fileBufferManager = [[NSArray alloc] initWithObjects:
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE],
							 [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE], nil];
		nGarbage = nThumbGarbage = 0;
	}
	
	return self;
}

- (NSString*)getHTMLPathWithHost:(NSString*)host
{
	NSString *path = [rootLocation stringByAppendingPathComponent:host];
	
	return [path stringByAppendingPathComponent:@"html"];
}

- (NSString*)getThumbPathWithHost:(NSString*)host
{
	NSString *path = [rootLocation stringByAppendingPathComponent:host];
	
	return [path stringByAppendingPathComponent:@"thumb"];
}

- (NSMutableArray*) getUrlForIndex:(NSString*)file forCategory:(cache_category_t)category
{
	NSMutableArray* objects = nil;
	NSArray *urls=nil;
	NSError *error; 
	NSString *stringFromFileAtPath = [[NSString alloc] 
									  initWithContentsOfFile:file
									  encoding:NSUTF8StringEncoding 
									  error:&error]; 
	if (stringFromFileAtPath == nil) { 
		// an error occurred 
		NSLog(@"Error reading file at %@\n%@", 
			  file, [error localizedFailureReason]); 
	}
	else {
		urls = [stringFromFileAtPath componentsSeparatedByString:@"\n"];
		[stringFromFileAtPath release];
		objects = [[NSMutableArray alloc] initWithCapacity:[urls count]];
		CacheObject *anObject = nil;
		// Since there is other way of creating url array, where it will be created.
		// instead here it is owned by pool, so we will need to retain it.
		for (NSString *str in urls) {
			//[str retain];
			if ([str length] > 1) {
				anObject = [[CacheObject alloc] init];
				anObject.url = str;
				anObject.category = category;
				[objects addObject:anObject];
			}
		}
	}
		
	//[urls release];
	return objects;
}

- (BOOL)checkExpiration:(NSString*)file 
{
	BOOL ret = YES;
	//NSDate *expirationDate = nil;
	//NSString *responseFile = [file stringByAppendingString:@".req"];
	BOOL unknown = YES;
	
	/*
	NSData *responseData = [self readFromFile:responseFile]; 

	if (responseData == nil) {
		NSLog(@"%s, can't open file. %@", __func__, file);
		return NO;
	}
	NSString *fieldName = nil;
	NSString *fieldValue = nil;
	const char* response = (const char*) [responseData bytes];
	int size = [responseData length];
	
	BOOL cont = YES;
	response_parser_mode_t parserMode = SEARCH_PROTOCOL_TYPE;
	NSInteger markIndex=0, currentIndex=0;
	
	do {
		switch (parserMode) {
			case SEARCH_PROTOCOL_TYPE:
				if (response[currentIndex] == ' ') {
					parserMode = SEARCH_GET_RESULT;
					currentIndex++;
					markIndex = currentIndex;
					continue;
				}
				
				currentIndex++;
				break;
			case SEARCH_GET_RESULT:
				if (response[currentIndex] == ' ') {
					parserMode = SKIP_TO_NEXT_LINE;
					continue;
				}
				
				currentIndex++;
				
				break;				
			case BEGIN_NEW_LINE:
				markIndex = currentIndex;
				if (((currentIndex + 1) < size) && 
					((response[currentIndex] == CARRIAGE_RETURN) && (response[currentIndex+1] == LINE_FEED))) {
					currentIndex += 2;
					parserMode = BODY_FOUND;
					cont = NO;
					break;
				}
				else {
					parserMode = SEARCH_FIELD;
				}
				break;
			case SEARCH_FIELD:
				if (response[currentIndex] == ':') {
					// found a field
					fieldName = [[NSString alloc] initWithBytes:&response[markIndex] length:currentIndex - markIndex encoding:NSUTF8StringEncoding];
					currentIndex++;
					if ([fieldName compare:EXPIRES_FIELD options:NSCaseInsensitiveSearch] == NSOrderedSame) {
						markIndex = currentIndex;
						parserMode = SEARCH_VALUE;
						[fieldName release];
						continue;
					}
					else {
						[fieldName release];
						parserMode = SKIP_TO_NEXT_LINE;
						continue;
					}
				}
				currentIndex++;
				break;
			case SEARCH_VALUE:
				if (((currentIndex + 1) < size) && 
					((response[currentIndex] == CARRIAGE_RETURN) && (response[currentIndex+1] == LINE_FEED))) {
					fieldValue = [[NSString alloc] initWithBytes:&response[markIndex] length:currentIndex - markIndex encoding:NSUTF8StringEncoding];
					
					TRACE("%s, found date: %s\n", __func__, [fieldValue UTF8String]);
					cont = NO;
					break;
					
					//currentIndex += 2;
					//parserMode = BEGIN_NEW_LINE;
					//break;
				}
				else if (response[currentIndex] == ' ') {
					markIndex++;
				}
				
				currentIndex++;
				break;
			case SKIP_TO_NEXT_LINE:
				if (((currentIndex + 1) < size) && 
					((response[currentIndex] == CARRIAGE_RETURN) && (response[currentIndex+1] == LINE_FEED))) {
					currentIndex += 2;
					parserMode = BEGIN_NEW_LINE;
					break;
				}
				currentIndex++;
				break;
			case BODY_FOUND:
				break;
			default:
				NSLog(@"Unknown parser mode: %d", parserMode);
		}
	} while ((cont == YES) && (currentIndex < size));
		
	if (fieldValue != nil) {
		NSDateFormatter *formater = [[NSDateFormatter alloc] init];
		[formater setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"];
		NSDate *expire_date = [formater dateFromString:fieldValue];
		if (expire_date == nil) {
			[formater setDateFormat:@"d MMM yyy HH:mm:ss zzz"];
			expire_date = [formater dateFromString:fieldValue];
		}
		
		if (expire_date == nil) {
			NSLog(@"%s, unknown date format detected. %@", __func__, fieldValue);
			ret = NO;
			unknown = YES;
		}
		else {
			expire_date = [expire_date addTimeInterval:43200.0];
			
			NSDate *today = [NSDate date];
			
			//time_t today = time(nil);
			
			if ([today compare:expire_date] == NSOrderedDescending) {
				//if (today > expire_date ) {
				// Give hour margin due to daylight saving. 
				// content is expired.
				ret = NO;
			}
			NSLog(@"%s, f: %@, today: %@, expires: %@, --> %d\n", __func__, fieldValue, today, expire_date, ret);
		}
		[formater release];
		[fieldValue release];
		
	}
	else {
		unknown = YES;
		NSLog(@"%s, couldn't get expiration date, assume expired.", __func__);
		ret = NO;
	}
	
	[responseData release];
	*/
	if (unknown == YES) {
		NSDate *last_updated = [Configuration sharedConfigurationInstance].lastUpdatedDate;
		NSDate *expired_date = [last_updated addTimeInterval:21600.0];
		NSDate *date = [[NSDate date] init];
		
		if ([expired_date compare:date] == NSOrderedAscending) {
			TRACE("%s, expired by last saved date.\n", __func__);
			ret = NO;
		}
		else {
			ret = YES;
		}
	}
	
	return ret;
}

- (NSString*)getLocalFileNameFromURL:(NSString*)url
{
	unichar *extension = getExtensionFromURL(url);
	
	NSString* file = nil;
	if (extension) {
		file = [NSString stringWithFormat:@"%u%S", [url hash], extension];
		free(extension);
	}
	else {
		file = [NSString stringWithFormat:@"%u", [url hash]];
	}

	return file;
}


/*
 * checkCacheAndRegister
 *    check cache to see if there is an entry. If not, then it will register one in the cache.
 *
 *    Each entry will have array of (url, category) for protecting cache collisision case. 
 *    Key: will be the file name and extesion only. The key is generated from the original url string, 
 *         so it will be unique enough. But we still need to prepare for the collision case. 
 *    Entry: will an array that contains (url, category). 
 *         url is the original url, and the category will be used for identifing the ogirinal category. 
 *         A local name will be created from the local file name and the category. 
 *
 */
- (NSString*)checkCacheAndRegister:(NSString*)url withFile:(NSString**)localFile forIndexFile:(NSString**)indexName fromCategory:(cache_category_t)category isAvailable:(BOOL*)available isCollide:(BOOL*)collision
{
	NSString* cachedFile = nil;
	unichar *extension = getExtensionFromURL(url);
	NSString *category_component = getCategoryComponent(category);
	
	@synchronized(self) {
		NSString* file = nil;
		if (extension) {
			file = [NSString stringWithFormat:@"%u%S", [url hash], extension];
			free(extension);
		}
		else {
			file = [NSString stringWithFormat:@"%u", [url hash]];
		}
		
		//NSLog(@"%s, url: %@, file: %@", __func__, url, file);	
		
		NSString* indexFile = nil;
		NSMutableArray *urls = [cacheObjects objectForKey:file];
		NSString *indexComponent = nil;
		
		if (urls != nil) {
			// see if we have collision. 
			int i=0;
			for (i=0; i<[urls count]; ++i) {
				CacheObject *anEntry = [urls objectAtIndex:i]; 
				NSString *urlString = anEntry.url;
				if ([urlString compare:url] == NSOrderedSame) {
					// found the right file
					indexComponent = getCategoryComponent(anEntry.category);
					indexFile = [indexLocation stringByAppendingPathComponent:hostForCacheObjects];
					indexFile = [[indexFile stringByAppendingPathComponent:indexComponent] stringByAppendingPathComponent:file];
					
					if (i == 0) {
						// this is the first one created
						cachedFile = [rootLocation stringByAppendingPathComponent:hostForCacheObjects];
						cachedFile = [[cachedFile stringByAppendingPathComponent:indexComponent] stringByAppendingPathComponent:file];
						//NSLog(@"Found in cache: %@, file: %@", url, file);
					}
					else {
						// TODO: this is not the first one
						cachedFile = [rootLocation stringByAppendingPathComponent:hostForCacheObjects];
						cachedFile = [cachedFile stringByAppendingPathComponent:indexComponent];
						cachedFile = [cachedFile stringByAppendingFormat:@"/%d-%s",i,[file UTF8String]];
						NSLog(@"###### Detect duplicated cache entry: %@", cachedFile);
						if (collision != nil) *collision = YES; 
					}
					*available = YES;
					
					// If the category in cache differs from the one requesting, consider the following:
					//  - This may be the case some duplicate objects are existing in different place. 
					//  - If the requesting category is higher then the one in cache, do this:
					//     --> Copy the current item if there is to the new destiation with the requesting category.
					//     --> Update the current category to the requesting one.
					if (anEntry.category < category) {
						NSLog(@"##### Detect potential duplicate item: %@ for category: %d", cachedFile, category);
						if (copyToNewCategory(cachedFile, indexComponent, category) == NO) {
							// donesn't exist, so remove it here. will be added later.
							[urls removeObject:anEntry];
							*available = NO;
						}
						else {
							anEntry.category = category;
							replaceToNewCategory(&indexFile, &cachedFile, indexComponent, category);
							*available = YES;
						}
					}

					break;
				}
			}
			
			if (*available == NO) {
				// Duplicated entry but not found entries, so we will have to create one.
				CacheObject *entry = [[CacheObject alloc] init];
				entry.url = url;
				entry.category = category;
				[urls addObject:entry];
				indexComponent = getCategoryComponent(category);
				indexFile = [indexLocation stringByAppendingPathComponent:hostForCacheObjects];
				indexFile = [[indexFile stringByAppendingPathComponent:indexComponent] stringByAppendingPathComponent:file];
				
				cachedFile = [rootLocation stringByAppendingPathComponent:hostForCacheObjects];
				cachedFile = [cachedFile stringByAppendingPathComponent:category_component];
				if (i > 0) {
					cachedFile = [cachedFile stringByAppendingFormat:@"/%d-%s",i,[file UTF8String]];
				}
				else {
					cachedFile = [cachedFile stringByAppendingFormat:@"/%s",[file UTF8String]];
				}
				NSLog(@"###### Detect duplicated cache entry, but has to be created: %@", cachedFile);		
				if (collision != nil) *collision = YES;
			}
#ifndef	CHECK_LATER
			else if (category == CACHE_FEED) {
				// check expiration date
				*available = [self checkExpiration:cachedFile];
			}
#endif
		}
		else {
			// file does not exist in cache.
			indexFile = [indexLocation stringByAppendingPathComponent:hostForCacheObjects];
			indexFile = [[indexFile stringByAppendingPathComponent:category_component] stringByAppendingPathComponent:file];
			
			cachedFile = [rootLocation stringByAppendingPathComponent:hostForCacheObjects];
			cachedFile = [[cachedFile stringByAppendingPathComponent:category_component] stringByAppendingPathComponent:file];
			//[cachedFile stringByAppendingPathComponent:file];
			
			//NSLog(@"Not in cache: %@, %@", indexFile, url);
			CacheObject *entry = [[CacheObject alloc] init];
			entry.url = url;
			entry.category = category;
			NSMutableArray *urlArray = [[NSMutableArray alloc] initWithObjects:entry, nil];
			
			[cacheObjects setObject:urlArray forKey:file];
			
		}
		
		*localFile = file;
		*indexName = indexFile;
	}

	return cachedFile;
}

/*
 * getCachedFileName:
 *	Getting cache file name for web objects.
 *	There are three folder for the cache.
 *	
 *	index: will store the index of the file, it's a main cache mechanism.
 *		The index file may be directly translate to the original URL by hash. 
 *		The index file will store the original URL. 
 *		If there is hash collision, then will have more than one URLs in the file. 
 *		In that case the cache file will be hash + the index of the URL in the file.
 *
 *  cache: will store the file, will be uniquely identified by the index file.
 *
 *  embedded: will store the mean for embedded object for the page.
 *		the file name will be identified by indexing and the file will 
 *      store the embedded objects <orig URL, local name>. 
 *
 *  Some interesting points.
 *  -------------------------------------------
 *  1. To come up with the local file name for an embedded object, 
 *     will need to store file in the index file. 
 *     However, if a file is existed in the index file, the cache will 
 *     decided it exists in the cache and will not get it from Web. 
 *  2. While it is parsing a page, will need to access the file manager.
 *	   --> potential performance problem.
 */
- (CacheEntry*)getCachedFileName:(NSURL*)url withCategory:(cache_category_t)category isAvailable:(BOOL*)available 
{
	CacheEntry* theEntry = nil;
	NSString* cachedFile = nil;
	NSString *file = nil;
	NSString *indexFile = nil;
		
	*available = NO;
	
	// check the availability of the file.
	cachedFile = [self checkCacheAndRegister:[url absoluteString] withFile:&file forIndexFile:&indexFile fromCategory:category isAvailable:available isCollide:nil];
	
	theEntry = [[CacheEntry alloc] initWithIndex:indexFile andCacheFile:cachedFile andURL:url];
	
	if (*available == YES && category == CACHE_HTML) {
		// TODO: remove it from gabage entry so it can't be removed from the cache
		[garbageDictionary removeObjectForKey:file];
	}
	
	return theEntry;
}

- (void)prepareEmbeddedObjectsStorage:(CacheEntry*)cacheEntry
{
	
	[cacheEntry retain];
	
	NSString* name = [cacheEntry.cacheFile stringByAppendingString:EMBEDDED_FILE_EXT];
	//NSString* embeddedFile = [rootLocation stringByAppendingPathComponent:hostForCacheObjects];
	//embeddedFile = [embeddedFile stringByAppendingPathComponent:name];
	
	theEmbeddedObjects = [[EmbeddedObjects alloc] initWithName:name];
	
	[cacheEntry release];
}

- (void)saveEmbeddedObjectsToStorage
{
	[theEmbeddedObjects saveToStorage];
	[theEmbeddedObjects release];
}

- (void)saveToCache:(CacheEntry*)entry withData:(NSData*)data
{
	[entry retain];
	if ([fileManager createFileAtPath:getActualPath(entry.cacheFile) contents:data attributes:nil] == NO) {
		NSLog(@"%s, fail to create a file: %@", __func__, entry.cacheFile);
		return;
	}
	
	NSString *url = [entry.origURL absoluteString];
	url = [url stringByAppendingString:@"\n"];
	/*
	 NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:entry.indexFile];
	 if (handle != nil) {
	 [handle writeData:[url dataUsingEncoding:NSUTF8StringEncoding]];
	 [handle closeFile];
	 }
	 else {
	 NSLog(@"%s, can't opne for writing: %@", __func__, entry.indexFile);
	 }
	 */
	if ([fileManager createFileAtPath:getActualPath(entry.indexFile) contents:[url dataUsingEncoding:NSUTF8StringEncoding] attributes:nil] == NO) {
		NSLog(@"%s, fail to create file: %@", __func__, entry.indexFile);
	}
	//NSLog(@"%s, %@", __func__, entry.indexFile);
	[entry release];
	//[url release]; <-- auto released.
}

- (void)flushCacheEntry:(CacheEntry*)entry
{
	[entry retain];
	NSString *url = [entry.origURL absoluteString];
	url = [url stringByAppendingString:@"\n"];
	if ([fileManager createFileAtPath:getActualPath(entry.indexFile) contents:[url dataUsingEncoding:NSUTF8StringEncoding] attributes:nil] == NO) {
		NSLog(@"%s, fail to create file: %@", __func__, entry.indexFile);
	}
	TRACE("%s, %s\n", __func__, [entry.indexFile UTF8String]);
	[entry release];
}

/*
 * getLocalName:
 *   get the local cache file name for the URL.
 *   1. generate hash file name from the url. 
 *   2. check there is an index file existed.
 *      if yes, check the original URL in the file. 
 *         if there is a matching URL, then cache entry is existed.
 *	       otherwise, add the URL at the end of the file since this is the collision.
 *   3. generate cache file name accordingly. --> this will be the local name.
 *
 * Perfromance issue:
 * ------------------
 *   not only accessing an index file, it also reads file content. 
 *       --> this can significantly lower the performance. 
 *
 * Improvements:
 * -------------
 *   Read the index file in memory. It can be done per host basis. 
 *   ===> the cache description should be in the memory. 
 */
- (NSString*)getLocalName:(NSString*)url withCategory:(cache_category_t)category withHandler:(ParserHandler*)handler
{
	NSString *local=nil;
	
	//NSLog(@"%s, url: %@, ext: %S", __func__, url, extension);
	NSString *file;
	NSString *indexFile=nil;
	BOOL collision = NO;
	BOOL available = NO;
	
	@try {
		// check the availability of the file.
		local = [self checkCacheAndRegister:url withFile:&file forIndexFile:&indexFile fromCategory:category isAvailable:&available isCollide:&collision];
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
	// if it exists in the cache already, don't write into index file. 
	//       Shoulde be written into the embedded object though. 
	[theEmbeddedObjects addEmbeddedObject:url withLocalName:local withIndexName:indexFile wasCollided:collision];
	
	return local;
}

- (NSString*)getLocalName:(NSString*)url withHandler:(ParserHandler*)handler
{
	return [self getLocalName:url withCategory:CACHE_NONE withHandler:handler];
}

- (void)saveResponseHeader:(NSData*)response withLocalFile:(NSString*)file
{	
	NSString *name = [getActualPath(file) stringByAppendingString:@".req"];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager createFileAtPath:name contents:response attributes:nil] == NO) {
		NSLog(@"%s, fail to create file: %@", __func__, file);
	}
}

- (void)moveTheCurrentEmbeddedObjectToFront
{
	[theEmbeddedObjects moveTheCurrentEmbeddedObjectToFront];
}

- (void)postProcessing:(CacheEntry*)cacheEntry atIndex:(NSIndexPath*)indexPath
{
	[cacheEntry retain];
	
	NSString* name = [cacheEntry.cacheFile stringByAppendingString:EMBEDDED_FILE_EXT];
	
	int fd = OPEN(name, O_RDONLY);
	if (fd == -1) {
		NSLog(@"%s: %@, %s", __func__, name, strerror(errno));
		[cacheEntry release];
		return;
	}
	int size = 0;
	
	size = read(fd, temp_storage, MAX_LINE_LEN);
	if (size == -1) {
		NSLog(@"%s: %@, %s", __func__, name, strerror(errno));
		goto clean;
	}
	else if (size == 0) {
		NSLog(@"%s, %@, end of file read", __func__, name);
		goto clean;
	}
	NSString *url = nil;
	NSString *local_name = nil;
	scanTwoStrings(temp_storage, size, &url, &local_name);
	
	if (isPicture(local_name) == YES)
		[ThumbNailHolder addThumbnail:url withLocalName:local_name atIndexPath:indexPath];

	// otherwise, it must not the thumbnail.
	
	[url release];
	[local_name release];


clean:
	[cacheEntry release];
	close(fd);
}

- (NSData*)getNextFileBuffer
{
	currentFileBufferIndex = (currentFileBufferIndex + 1) % MAX_FILE_BUFFERS;
	
	return [fileBufferManager objectAtIndex:currentFileBufferIndex];
}

- (NSData*)readFromFile:(NSString*)file
{
	int size = 0;
	int totalLength = 0;
	NSMutableData *data = nil;
	int fd = -1;
	
	
	@synchronized (self) {
		fd = OPEN(file, O_RDONLY);
		if (fd == -1) {
			NSLog(@"%s: %@, %s", __func__, file, strerror(errno));
			return nil;
		}
		
		
		//NSMutableData *data = [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE];
		data = (NSMutableData*) [self getNextFileBuffer];
		[data retain];
		[data setLength:0];
		
		do {
			size = read(fd, temp_file_storage, BLOCK_SIZE);
			if (size > 0) {
				[data appendBytes:temp_file_storage length:size];
			}
			else if (size < 0) {
				NSLog(@"%s: %@, %s", __func__, file, strerror(errno));
				//[data release];
				close(fd);
				return nil;
			}
			totalLength += size;
		} while (size > 0);
		
		close(fd);
	}
	
	
	//NSData *data = [[NSFileManager defaultManager] contentsAtPath:file];
	//[data retain];
	return data;
}

- (NSData*)readFromFileDescriptor:(int)fd withBlockSize:(int)block_size
{
	int size = 0;
	int totalLength = 0;
	NSMutableData *data = nil;
	
	if (fd == -1) {
		NSLog(@"%s: %s", __func__, strerror(errno));
		return nil;
	}
	
	@synchronized (self) {
		
		//NSMutableData *data = [[NSMutableData alloc] initWithCapacity:block_size];
		data = (NSMutableData*) [self getNextFileBuffer];
		[data retain];
		[data setLength:0];
		
		do {
			size = read(fd, temp_file_storage, block_size);
			if (size > 0) {
				[data appendBytes:temp_file_storage length:size];
			}
			else if (size < 0) {
				NSLog(@"%s: fd: %d, %s", __func__, fd, strerror(errno));
				//[data release];
				close(fd);
				return nil;
			}
			totalLength += size;
		} while (size > 0);
		
		close(fd);
	}
	return data;
}

- (BOOL)hasThisFile:(NSString*)file atIndex:(NSIndexPath*)indexPath
{
	BOOL ret = NO;
	
	NSFileManager *manager = [NSFileManager defaultManager];

	if ([manager fileExistsAtPath:getActualPath(file)] == YES) {
		[ArticleStorage setImageLink:file atIndexPath:indexPath];
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:nil	waitUntilDone:YES];
		ret = YES;
	}
	return ret;
}

- (NSString*)getIndexDescriptorFromCacheFile:(NSString*)file
{
	NSRange range = [file rangeOfString:@"cache"];
	NSString *indexFile = [file stringByReplacingCharactersInRange:range withString:@"index"];
	return indexFile;
}

- (BOOL)isCacheCreated
{
	NSFileManager *manager = [NSFileManager defaultManager];
	
	if ([manager fileExistsAtPath:getActualPath(rootLocation)] == YES && [manager fileExistsAtPath:getActualPath(indexLocation)] == YES)
		return YES;
	
	return NO;
}
/* loadCacheObjects:
 *	Load cache objects for the host. The cache object consists of 
 *	 1. index files: files on index folder for the host.
 *      -> NSDictionary <FileName, URLs>
 *   2. The content of the file
 *      -> NSArray <NSString>
 *
 *   TODO: It takes too long when everything is done. Too many files to load.
 *         How can we distribute the load evenly to the feeds?
 *          -> if we separate each feed, then an object will be unique only per feed, not entirely for the site.
 *          -> we may separate HTML/jpg/xml and so on. we may be able to cut the forth of it. 
 *             so the sequence will be 
 *               XML -> Articles -> Thumbnail -> the rest.
 */
- (void)initCacheObjects:(NSString*)host
{
	// TODO: make sure loading for the host only.
	//       will have to unload if the host changes.
	hostForCacheObjects = host;
	
	TRACE("host: %s\n", [host UTF8String]);
	// check the folder exists or not
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = getActualPath(rootLocation);
	if ([manager fileExistsAtPath:path] == NO) {
		[manager createDirectoryAtPath:path attributes:nil];
	}
	
	path = getActualPath(indexLocation);
	if ([manager fileExistsAtPath:path] == NO) {
		[manager createDirectoryAtPath:path attributes:nil];
	}
	
	// Create index directory
	NSString *indexdir = [getActualPath(indexLocation) stringByAppendingPathComponent:host];
	if ([manager fileExistsAtPath:indexdir] == NO) {
		[manager createDirectoryAtPath:indexdir	attributes:nil];
	}
	NSString *feeddir = [indexdir stringByAppendingPathComponent:FEED_DIR_COMPONENT];
	if ([manager fileExistsAtPath:feeddir] == NO) {
		[manager createDirectoryAtPath:feeddir attributes:nil];
	}
	NSString *htmldir = [indexdir stringByAppendingPathComponent:HTML_DIR_COMPONENT];
	if ([manager fileExistsAtPath:htmldir] == NO) {
		[manager createDirectoryAtPath:htmldir attributes:nil];
	}
	NSString *thumbdir = [indexdir stringByAppendingPathComponent:THUMB_DIR_COMPONENT];
	if ([manager fileExistsAtPath:thumbdir] == NO) {
		[manager createDirectoryAtPath:thumbdir attributes:nil];
	}
	NSString *defaultdir = [indexdir stringByAppendingPathComponent:DEFAULT_DIR_COMPONENT];
	if ([manager fileExistsAtPath:defaultdir] == NO) {
		[manager createDirectoryAtPath:defaultdir attributes:nil];
	}
	
	// Create cache directory
	NSString *cachedir = [getActualPath(rootLocation) stringByAppendingPathComponent:host];
	if ([manager fileExistsAtPath:cachedir] == NO) {
		[manager createDirectoryAtPath:cachedir attributes:nil];
	}
	feeddir = [cachedir stringByAppendingPathComponent:FEED_DIR_COMPONENT];
	if ([manager fileExistsAtPath:feeddir] == NO) {
		[manager createDirectoryAtPath:feeddir attributes:nil];
	}
	htmldir = [cachedir stringByAppendingPathComponent:HTML_DIR_COMPONENT];
	if ([manager fileExistsAtPath:htmldir] == NO) {
		[manager createDirectoryAtPath:htmldir attributes:nil];
	}
	thumbdir = [cachedir stringByAppendingPathComponent:THUMB_DIR_COMPONENT];
	if ([manager fileExistsAtPath:thumbdir] == NO) {
		[manager createDirectoryAtPath:thumbdir attributes:nil];
	}
	defaultdir = [cachedir stringByAppendingPathComponent:DEFAULT_DIR_COMPONENT];
	if ([manager fileExistsAtPath:defaultdir] == NO) {
		[manager createDirectoryAtPath:defaultdir attributes:nil];
	}
	
}

- (void)emptyCache
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	
	if ([manager removeItemAtPath:getActualPath(indexLocation) error:(NSError **)error] == NO) {
		NSLog(@"%s, error in emptying cache: %s", __func__, error);
	}
	if ([manager removeItemAtPath:getActualPath(rootLocation) error:(NSError **)error] == NO) {
		NSLog(@"%s, error in emptying cache: %s", __func__, error);
	}
}

- (NSInteger)loadCacheObjectsFromCategory:(cache_category_t)category
{
	NSInteger i=0;
	NSString *indexdir = [getActualPath(indexLocation) stringByAppendingPathComponent:hostForCacheObjects];
	indexdir = [indexdir stringByAppendingPathComponent:getCategoryComponent(category)];
		
	NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] 
									  enumeratorAtPath:indexdir];
	//[indexdir release]; <-- this must be auto released.
	NSString *filename; 
	NSArray *urls;
	NSString *full_path;
	TRACE("%s\n", __func__);
	while (filename = [direnum nextObject]) 
	{ 
		full_path = [indexdir stringByAppendingPathComponent:filename];
		urls = [self getUrlForIndex:full_path forCategory:category];
		
		[cacheObjects setObject:urls forKey:filename];	
		if (category == CACHE_HTML) {
			[garbageDictionary setObject:dummy forKey:filename];
		}
		else if (category == CACHE_THUMB_NAIL) {
			[thumbDictionary setObject:dummy forKey:filename];
		}
		TRACE("Loading object: %s, %p\n", [filename UTF8String], filename);
		++i;
	} 	
	
	return i;
}

- (void)addToCSSDictionary:(embedded_object_t*)object
{
	if ([cssDictionary objectForKey:object.local_name] ==	nil) {
		[cssDictionary setObject:object.orig_url forKey:object.local_name];
		numberOfCSSs++;
	}
}

- (NSArray*)getDummyObjecs:(NSInteger)count
{
	NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:count];
	
	for (int i = 0; i<count; ++i) {
		[objects addObject:[[NSObject alloc] init]];
	}
	
	return objects;
}

/*
 * unlinkThisFile:
 *   unlink this file from cache.
 *   has to be unlinked from cache/index folder. 
 *   The real question is how we will unlink all the embedded objects.
 *   To remove unused file from cache, we will need to have better mechanism. 
 *     --> some kind of reference count. 
 *     --> automatically deleted. 
 */
- (void)unlinkThisFile:(NSString*)file
{
	NSError *error = nil;
	NSMutableData *objects = nil;
	NSMutableDictionary *objectDictionary = nil;
	
	NSString* name = [rootLocation stringByAppendingFormat:@"%@/html/%@%@", hostForCacheObjects, file, EMBEDDED_FILE_EXT];
	NSString* request_name = [rootLocation stringByAppendingFormat:@"%@/html/%@.req", hostForCacheObjects, file];
	NSString* orig_name = [rootLocation stringByAppendingFormat:@"%@/html/%@", hostForCacheObjects, file];
	NSString* index_name = [indexLocation stringByAppendingFormat:@"%@/html/%@", hostForCacheObjects, file];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	int fd = OPEN(name, O_RDONLY);
	if (fd == -1) {
		NSLog(@"%s: %@, %s", __func__, name, strerror(errno));
		goto cleanLast;
	}
	
#ifdef CLEAN_MORE
	int size = 0;
	objects = [[NSMutableData alloc] initWithCapacity:MAX_LINE_LEN];
	
	do {
		size = read(fd, temp_storage, MAX_LINE_LEN);
		if (size == -1) {
			NSLog(@"%s: %@, %s", __func__, name, strerror(errno));
			goto clean;
		}
		
		[objects appendBytes:temp_storage length:size];
		
	} while (size > 0);
	
	NSString *url = nil;
	NSString *local_name = nil;
	objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
	//NSObject *dummy = [[NSObject alloc] init];
	
	int i = 0;
	unsigned char *bytes = (unsigned char*)[objects bytes];
	size = [objects length];
	
	if (size <= 0) {
		goto clean;
	}
	
	do {
		// identify file and register to dictionary
		i += scanTwoStrings(&bytes[i], size, &url, &local_name);	
		NSRange range = [local_name rangeOfString:@"thumb"];
		if (range.location == NSNotFound) {
			[objectDictionary setObject:dummy forKey:local_name];
		}
		[url release];
		[local_name release];
	} while (i > 0 && i < size);
	
	NSEnumerator *enumerator = [objectDictionary keyEnumerator];
	id key;
	time_t today = time(nil);
	
	int interval = GARBAGE_INTERVAL;
	while ((key = [enumerator nextObject])) {
		NSString *file = (NSString*) key;
		NSString *ext = [file pathExtension];
		if (([ext compare:@"css"] != NSOrderedSame) &&
			([ext compare:@"xml"] != NSOrderedSame)) {
			
			if (canThisBeGarbage(file, today, interval) == YES) {
				// remove this file
				[manager removeItemAtPath:file error:&error];
				if (error != nil) {
					NSLog(@"Error occurred during removing this file: %@, %@", file, error);
				}
				else {
					TRACE("File %s has been removed.\n", [file UTF8String]);
				}
			}
		}
	}
#endif
	
clean:
	if (fd >= 0) {
		close(fd);
	}
	[manager removeItemAtPath:getActualPath(name) error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", name, error);
	}
	[manager removeItemAtPath:getActualPath(orig_name) error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", orig_name, error);
	}
	[manager removeItemAtPath:getActualPath(request_name) error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", request_name, error);
	}
	[objectDictionary release];
	[objects release];
	
cleanLast:
	[manager removeItemAtPath:getActualPath(index_name) error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", index_name, error);
	}
	
}

-(void)removeThisFromGarbage:(NSString*)file
{
	[thumbDictionary removeObjectForKey:file];
}

- (BOOL)doGarbageCollection
{
	if ([garbageDictionary count] == 0)
		return NO;

	TRACE("****** Start garbage collection ******\n");
	NSEnumerator *enumerator = [garbageDictionary keyEnumerator];
	id key;
	
	key = [enumerator nextObject];
	if (key == nil)
		return NO;

	NSString *file = (NSString*) key;
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	
	if ([config isFileInHistory:file] == NO) {
		// Remove only when this file is not in hash.
		TRACE("%s needs to be removed.\n", [file UTF8String]);
		[self unlinkThisFile:file];
		nGarbage++;
	}
	
	[garbageDictionary removeObjectForKey:key];
	
	if ([garbageDictionary count] == 0) {
		NSLog(@"%s, garbage collected: %d", __func__, nGarbage);
		return NO;
	}
	
	return YES;
}

- (BOOL)unlinkThisThumbFile:(NSString*)file
{
	NSError *error = nil;
	//time_t today = time(nil);
	
	NSString* request_name = [getActualPath(rootLocation) stringByAppendingFormat:@"/%@/thumb/%@.req", hostForCacheObjects, file];
	NSString* orig_name = [getActualPath(rootLocation) stringByAppendingFormat:@"/%@/thumb/%@", hostForCacheObjects, file];
	NSString* index_name = [getActualPath(indexLocation) stringByAppendingFormat:@"/%@/thumb/%@", hostForCacheObjects, file];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	// TODO: Need more thought, probably for next version.
	//if (canThisBeGarbage(orig_name, today, CSS_GARBAGE_INTERVAL) == NO) {
	//	return NO;
	//}
	
	[manager removeItemAtPath:orig_name error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", orig_name, error);
	}
	[manager removeItemAtPath:request_name error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", request_name, error);
	}
	[manager removeItemAtPath:index_name error:&error];
	if (error != nil) {
		NSLog(@"Error occurred during removing this file: %@, %@", index_name, error);
	}
	return YES;
}

- (BOOL)doGarbageCollectionForThumbnail
{
	if ([thumbDictionary count] == 0) 
		return NO;
	
	TRACE("****** Start garbage collection for thumbnail ******\n");
	NSEnumerator *enumerator = [thumbDictionary keyEnumerator];
	id key;
	
	key = [enumerator nextObject];
	if (key == nil)
		return NO;
	
	NSString *file = (NSString*) key;
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	
	if ([config isThumbInHistory:file] == NO) {
		// Remove only when this file is not in hash.
		if ([self unlinkThisThumbFile:file] == YES) {
			NSLog(@"%s, removing this file: %s.\n", __func__, [file UTF8String]);
			nThumbGarbage++;
		}
	}
	
	[thumbDictionary removeObjectForKey:key];
	
	if ([thumbDictionary count] == 0) {
		NSLog(@"%s, thumb garbage collected: %d", __func__, nThumbGarbage);
		return NO;
	}

	return YES;
}

- (BOOL)doesCacheExist:(NSString*)file
{
	NSFileManager *manager = [NSFileManager defaultManager];
	return [manager fileExistsAtPath:getActualPath(file)];
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

/*
- (void)dealloc 
{
	[rootLocation release];
	[indexLocation release];
	[cacheObjects release];
	[hostForCacheObjects release];
	
	[super dealloc];
}
*/

- (void)releaseCacheEntries
{
	//NSEnumerator *enumerator = [cacheObjects objectEnumerator];
	//NSArray *object;
	//int i = 0;
	/*
	while ((object = (NSArray*)[enumerator nextObject])) {
		if (object) {
			
			for (i=0; i<[object count]; ++i) {
				NSString *url = [object objectAtIndex:i];
				[url release];
			}
			 
			[object release];
		}
		
	}
	*/
	[cacheObjects release];
	//[rootLocation release];
	//[indexLocation release];
	//[hostForCacheObjects release];
	
}

+ (void)releaseCacheObject
{
	WebCacheService* cache = [WebCacheService sharedWebCacheServiceInstance];
	
	[cache releaseCacheEntries];
}
	

@end
