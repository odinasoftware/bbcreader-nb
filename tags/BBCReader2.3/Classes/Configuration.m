//
//  Configuration.m
//  NYTReader
//
//  Created by Jae Han on 8/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include <pthread.h>
#include <fcntl.h>
#include <sys/stat.h>
//#include <stdio.h>

#import "Configuration.h"
#import "WebCacheService.h"
#import "WebLink.h"
#import "ArticleStorage.h"
#import "NetworkService.h"

#define SEGMENT0			@"segment0"
#define SEGMENT1			@"segment1"
#define SEGMENT2			@"segment2"
#define SEGMENT3			@"segment3"
#define LAST_UPDATE_DATE	@"last"
#define WEB_HISTORY			@"web_history"
#define LAST_VERSION		@"last_version"
#define CACHE_CLEANED		@"cache_cleaned"
#define OFFLINE_MODE		@"offline_mode"

/*
 * Key definitions for WebLink history
 */
#define HISTORY_TEXT		@"history_text"
#define HISTORY_URL			@"history_url"
#define HISTORY_DESCRIPTION @"history_description"
#define HISTORY_IMG_LINK	@"history_img_link"

#define LAST_URL			@"last_url"

#define MAX_HISTORY_NUM 20

static Configuration *sharedConfiguration = nil;

NSString *readStringSeparatedBySpace(const char *data, int len, int *index)
{
	NSMutableString *str = [[NSMutableString alloc] init];
	int i = 0;
	for (i = *index; i < len; ++i) {
		if (data[i] == ' ') {
			// it may be the space in the beginning.
			if ([str length] > 0)
				break;
		}
		else if (data[i] == '\n') {
			// line separator, will stop here.
			break;
		}
		else {
			[str appendFormat:@"%c", data[i]];
		}
	}
	
	if (i >= len)
		*index = -1;
	else 
		*index = i;
	return str;
}

@implementation Configuration

@synthesize lastUpdatedDate;
@synthesize history;

+(Configuration*) sharedConfigurationInstance 
{
	@synchronized(self) {
		if (sharedConfiguration == nil) {
			[[self alloc] init];
		}
	}
	return sharedConfiguration;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized(self) { 
		if (sharedConfiguration == nil) { 
			sharedConfiguration = [super allocWithZone:zone]; 
			return sharedConfiguration; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

- (id)init 
{
	if ((self = [super init])) {
		//NSString *file = NSHomeDirectory();
		/*
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
															 NSUserDomainMask, YES); 
		NSString *documentsDirectory = [paths objectAtIndex:0]; 
		
		configLocation = [documentsDirectory stringByAppendingPathComponent:@"config.mag"];
		pthread_mutex_init(&fileMutex, nil);
		
		NSLog(@"Config file: %@", configLocation);
		 */
		// TODO: clean up these dictionary at some point.
		historyDictionary = [[NSMutableDictionary alloc] initWithCapacity:MAX_HISTORY_NUM];
		thumbHistoryDictionary = [[NSMutableDictionary alloc] initWithCapacity:MAX_HISTORY_NUM];
		cacheService = [WebCacheService sharedWebCacheServiceInstance];
		historyIndex = -1;
		[self readSettings];
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

/*
- (void)fillValues:(NSData*)data
{
	int i = 0;
	const char* buffer = (const char*) [data bytes];
	int len = [data length];
	
	// read the recent indexes
	NSString *first = readStringSeparatedBySpace(buffer, len, &i);
	NSString *second = readStringSeparatedBySpace(buffer, len, &i);
	NSString *third = readStringSeparatedBySpace(buffer, len, &i);
	//NSString *forth = readStringSeparatedBySpace(buffer, len, &i);
	NSString *date = readStringSeparatedBySpace(buffer, len, &i);
	
	segmentIndex[0] = [first intValue]; [first release];
	segmentIndex[1] = [second intValue]; [second release];
	segmentIndex[2] = [third intValue]; [third release];
	//segmentIndex[3] = [forth intValue]; [forth release];
	
	lastUpdatedDate = [date intValue]; [date release];
	
}
 */

- (void)useDefaultSettings
{
	//for (int i=0; i<NUMBER_OF_ACTIVE_FEED; ++i) {
	//	segmentIndex[i] = i;
	//}
	
	//segmentIndex[NUMBER_OF_ACTIVE_FEED-1] = 7; // UK news
	segmentIndex[0] = 17;
	segmentIndex[1] = 18;
	segmentIndex[2] = 19;
	
	lastUpdatedDate = nil;
}

- (void)readSettings
{
	
	// due to application data merging problem in application, better to remove all of that.
	NSString *version = (NSString*) CFPreferencesCopyAppValue((CFStringRef)LAST_VERSION, kCFPreferencesCurrentApplication);
	if (version) {
		TRACE("%s, version: %s", __func__, [version UTF8String]);
	}
	//NSNumber *cleaned = (NSNumber*) CFPreferencesCopyAppValue((CFStringRef)CACHE_CLEANED, kCFPreferencesCurrentApplication);
	//if (cleaned) {
	//	TRACE("%s, version: %d", __func__, cleaned);
	//}
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSDictionary *dict = [bundle infoDictionary];
	
	NSString *bundle_version = (NSString*)[dict objectForKey:@"CFBundleVersion"];
	BOOL needClearCache = NO;
	
	if (version) {
		if ([version compare:bundle_version] != NSOrderedSame && [cacheService isCacheCreated] == YES) {
			needClearCache = YES;
		}
	}
	else {
		needClearCache = NO;
	}
	
	if (needClearCache == YES) {
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showEmptyCacheWarning:) withObject:nil waitUntilDone:YES];
		[cacheService emptyCache];
		CFPreferencesSetAppValue((CFStringRef)LAST_VERSION, bundle_version, kCFPreferencesCurrentApplication);
		//CFPreferencesSetAppValue((CFStringRef)CACHE_CLEANED, [NSNumber numberWithInt:1], kCFPreferencesCurrentApplication);
	}
	
	NSNumber *isOffline = (NSNumber*) CFPreferencesCopyAppValue((CFStringRef)OFFLINE_MODE, kCFPreferencesCurrentApplication);
	if (isOffline) {
		[NetworkService sharedNetworkServiceInstance].offlineMode = [isOffline boolValue];
	}
	else {
		[NetworkService sharedNetworkServiceInstance].offlineMode = 0;
	}
	
	NSNumber *segment_index = (NSNumber*) CFPreferencesCopyAppValue((CFStringRef)SEGMENT0, kCFPreferencesCurrentApplication);
	if (segment_index) {
		segmentIndex[0] = [segment_index intValue];
	}
	else goto clean; 
		
	segment_index = (NSNumber*) CFPreferencesCopyAppValue((CFStringRef)SEGMENT1, kCFPreferencesCurrentApplication);
	if (segment_index) {
		segmentIndex[1] = [segment_index intValue];
	}
	else goto clean;
	
	segment_index = (NSNumber*) CFPreferencesCopyAppValue((CFStringRef)SEGMENT2, kCFPreferencesCurrentApplication);
	if (segment_index) {
		segmentIndex[2] = [segment_index intValue];
	}
	else goto clean;
	
	//segment_index = (NSNumber*) CFPreferencesCopyAppValue((CFStringRef)SEGMENT3, kCFPreferencesCurrentApplication);
	//if (segment_index) {
	//	segmentIndex[3] = [segment_index intValue];
	//}
	//else goto clean;
	
	lastUpdatedDate =(NSDate*) CFPreferencesCopyAppValue((CFStringRef)LAST_UPDATE_DATE, kCFPreferencesCurrentApplication);
	if ([lastUpdatedDate isKindOfClass:[NSNumber class]]) {
		lastUpdatedDate = nil;
	}
	
	//if (segment_index) {
	//	lastUpdatedDate = [segment_index intValue];
	//}
	//else goto clean;
	
clean:
	if (segment_index == nil)
		[self useDefaultSettings];
	
	history = [self readLinkHistory]; 
	NSLog(@"%s, read %d history.", __func__, [history count]);		
	if ([history count] > 0) {
		historyIndex = ([history count] - 1) % MAX_HISTORY_NUM;
	}
	
	/* TODO: Too much trouble in the beginning, don't do that now.
	lastUsedURLHash = (NSString*) CFPreferencesCopyAppValue((CFStringRef)LAST_URL, kCFPreferencesCurrentApplication);
	
	CFPreferencesSetAppValue((CFStringRef)LAST_URL, nil, kCFPreferencesCurrentApplication); 
	 */
	
	if (CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) == NO) {
		NSLog(@"%s, sync failed.", __func__);
	}
		
}

- (NSString*)getLastUsedURLHash
{
	return lastUsedURLHash;
}

- (void)saveSettings
{
	
	CFPreferencesSetAppValue((CFStringRef)SEGMENT0, [NSNumber numberWithInt:segmentIndex[0]], kCFPreferencesCurrentApplication);
	CFPreferencesSetAppValue((CFStringRef)SEGMENT1, [NSNumber numberWithInt:segmentIndex[1]], kCFPreferencesCurrentApplication);
	CFPreferencesSetAppValue((CFStringRef)SEGMENT2, [NSNumber numberWithInt:segmentIndex[2]], kCFPreferencesCurrentApplication);
	//CFPreferencesSetAppValue((CFStringRef)SEGMENT3, [NSNumber numberWithInt:segmentIndex[3]], kCFPreferencesCurrentApplication);
	//CFPreferencesSetAppValue((CFStringRef)LAST_UPDATE_DATE, [NSNumber numberWithInt:lastUpdatedDate], kCFPreferencesCurrentApplication);
	CFPreferencesSetAppValue((CFStringRef)LAST_UPDATE_DATE, lastUpdatedDate, kCFPreferencesCurrentApplication);
	
	if (CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) == NO) {
		NSLog(@"%s, sync failed.", __func__);
	}

}

- (void)setOfflineMode:(BOOL)mode
{
	CFPreferencesSetAppValue((CFStringRef)OFFLINE_MODE, [NSNumber numberWithBool:mode], kCFPreferencesCurrentApplication);
	
	if (CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) == NO) {
		NSLog(@"%s, set failed.", __func__);
	}
	
}

- (void)addWebHitory:(WebLink*)link
{
	NSString *file = [cacheService getLocalFileNameFromURL:link.url];
	
	if (file == nil) {
		NSLog(@"%s, adding null link", __func__);
		return;
	}
	
	if ([historyDictionary objectForKey:file] == nil) {
		historyIndex = ++historyIndex % MAX_HISTORY_NUM;
		
		if ([history count] >= historyIndex || [history objectAtIndex:historyIndex] == nil) {
			[history insertObject:link atIndex:historyIndex];
			[historyDictionary setObject:link forKey:file];
		}
		else {
			// should remove the old object
			[history removeObjectAtIndex:historyIndex];
			[historyDictionary removeObjectForKey:file];
		}
		
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateHistory:) withObject:nil waitUntilDone:YES];
		
		[self saveWebLinkPreference:link];
				
		if (CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) == NO) {
			NSLog(@"%s, sync failed.", __func__);
		}
	}
}

- (BOOL)isFileInHistory:(NSString*)file
{
	return ([historyDictionary objectForKey:file]==nil?NO:YES);
}

- (BOOL)isThumbInHistory:(NSString*)file
{
	return ([thumbHistoryDictionary objectForKey:file]==nil?NO:YES);
}

- (void)saveWebLinkPreference:(WebLink*)link
{
	NSString *key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_TEXT, historyIndex];
	CFPreferencesSetAppValue((CFStringRef)key, link.text, kCFPreferencesCurrentApplication); [key release];
	
	key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_URL, historyIndex];
	CFPreferencesSetAppValue((CFStringRef)key, link.url, kCFPreferencesCurrentApplication); [key release];
	
	key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_DESCRIPTION, historyIndex];
	CFPreferencesSetAppValue((CFStringRef)key, link.description, kCFPreferencesCurrentApplication); [key release];
	
	key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_IMG_LINK, historyIndex];
	CFPreferencesSetAppValue((CFStringRef)key, link.imageLink, kCFPreferencesCurrentApplication); [key release];
}

- (NSMutableArray*)readLinkHistory
{
	NSMutableArray* historyLink = [[NSMutableArray alloc] initWithCapacity:MAX_HISTORY_NUM];
	NSString *value = nil;
	NSString *key = nil;
	WebLink *link = nil;
	WebCacheService *service = [WebCacheService sharedWebCacheServiceInstance];
	NSFileManager *manager = [NSFileManager defaultManager];
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];	
	NSString *host = [storage getHost];
	NSString *html_path = [service getHTMLPathWithHost:host];
	
	for (int i=0; i<MAX_HISTORY_NUM; ++i) {
		key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_TEXT, i];
		value = (NSString*) CFPreferencesCopyAppValue((CFStringRef)key, kCFPreferencesCurrentApplication); [key release];
		
		if (value != nil) {
			link = [[WebLink alloc] init];
			link.text = value;
			
			key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_URL, i];
			value = (NSString*) CFPreferencesCopyAppValue((CFStringRef)key, kCFPreferencesCurrentApplication); [key release];
			link.url = value;
			
			key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_DESCRIPTION, i];
			value = (NSString*) CFPreferencesCopyAppValue((CFStringRef)key, kCFPreferencesCurrentApplication); [key release];
			link.description = value;
			
			key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_IMG_LINK, i];
			value = (NSString*) CFPreferencesCopyAppValue((CFStringRef)key, kCFPreferencesCurrentApplication); [key release];
			link.imageLink = value;
			
			if (link.url != nil && link.description != nil) {
				
				NSString *file = [cacheService getLocalFileNameFromURL:link.url];
				NSString *file_path = [html_path stringByAppendingPathComponent:file];
				if ([manager fileExistsAtPath:getActualPath(file_path)] && [historyDictionary objectForKey:file] == nil) {
					TRACE("%s: add %s: %s to history.\n", __func__, [link.url UTF8String], [file UTF8String]);
					[historyLink addObject:link];
					[historyDictionary setObject:link forKey:file];
					if (link.imageLink != nil) {
						file = [link.imageLink lastPathComponent];
						if ([manager fileExistsAtPath:getActualPath(link.imageLink)] && [thumbHistoryDictionary objectForKey:file] == nil) {
							[thumbHistoryDictionary setObject:link.imageLink forKey:file];
							NSLog(@"Add this thumb to history: %@", file);
						}
					}
				}
				else {
					TRACE("%s, this will not be added: %s\n", __func__, [file UTF8String]);
					[link release];
				}

			}
			else {
				NSLog(@"%s, invalid link found.", __func__);
			}
		}
	}
	
	return historyLink;
}

- (void)saveURLForNextTime:(NSString*)url
{
	NSString *file = [cacheService getLocalFileNameFromURL:url];
	
	CFPreferencesSetAppValue((CFStringRef)LAST_URL, file, kCFPreferencesCurrentApplication); 
	
	if (CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) == NO) {
		NSLog(@"%s, sync failed.", __func__);
	}
}

- (WebLink*)getHistoryLinkFromURL:(NSString*)url_hash
{
	return [historyDictionary objectForKey:url_hash];
}

- (void)clearHistory
{
	historyIndex = -1;
	[history removeAllObjects];
	
	for (int i=0; i<MAX_HISTORY_NUM; ++i) {
		NSString *key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_TEXT, i];
		CFPreferencesSetAppValue((CFStringRef)key, nil, kCFPreferencesCurrentApplication); [key release];
		
		key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_URL, i];
		CFPreferencesSetAppValue((CFStringRef)key, nil, kCFPreferencesCurrentApplication); [key release];
		
		key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_DESCRIPTION, i];
		CFPreferencesSetAppValue((CFStringRef)key, nil, kCFPreferencesCurrentApplication); [key release];
		
		key = [[NSString alloc] initWithFormat:@"%@%d", HISTORY_IMG_LINK, i];
		CFPreferencesSetAppValue((CFStringRef)key, nil, kCFPreferencesCurrentApplication); [key release];
	}
	
	if (CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) == NO) {
		NSLog(@"%s, sync failed.", __func__);
	}
}

- (void)setIndex:(NSInteger)index withNewIndex:(NSInteger)newIndex
{
	segmentIndex[index] = newIndex;
	//[self saveSettings];
}

- (void)setIndex:(NSInteger)index withNewIndex:(NSInteger)newIndex fromSegment:(NSInteger)segment 
{
	segmentIndex[segment] = segmentIndex[index];
	segmentIndex[index] = newIndex;
	[self saveSettings];
}

- (NSInteger*)indexes
{
	return segmentIndex;
}

@end
