//
//  Configuration.h
//  NYTReader
//
//  Created by Jae Han on 8/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUMBER_OF_ACTIVE_FEED 4

@class WebCacheService;
@class WebLink;

@interface Configuration : NSObject {
	NSInteger		segmentIndex[NUMBER_OF_ACTIVE_FEED];
	NSDate			*lastUpdatedDate;
	
	@private
	NSString		*configLocation;
	pthread_mutex_t fileMutex;
	NSMutableArray	*history;
	NSMutableDictionary *historyDictionary;
	NSMutableDictionary *thumbHistoryDictionary;
	int				historyIndex;
	WebCacheService *cacheService;
	NSString		*lastUsedURLHash;
	BOOL			sectionSectionDone;
}

@property (nonatomic, retain) NSDate *lastUpdatedDate;
@property (nonatomic, retain) NSMutableArray *history;

+(Configuration*) sharedConfigurationInstance;
//- (void)fillValues:(NSData*)data;
- (void)readSettings;
- (void)saveSettings;
- (void)setIndex:(NSInteger)index withNewIndex:(NSInteger)newIndex;
- (void)setIndex:(NSInteger)index withNewIndex:(NSInteger)newIndex fromSegment:(NSInteger)segment;
- (NSInteger*)indexes;
- (void)addWebHitory:(WebLink*)link;
- (void)saveWebLinkPreference:(WebLink*)link;
- (NSMutableArray*)readLinkHistory;
- (NSString*)getLastUsedURLHash;
- (void)saveURLForNextTime:(NSString*)url;
- (WebLink*)getHistoryLinkFromURL:(NSString*)url_hash;
- (BOOL)isFileInHistory:(NSString*)file;
- (void)setOfflineMode:(BOOL)mode;
- (void)clearHistory;
- (BOOL)isThumbInHistory:(NSString*)file;

@end
