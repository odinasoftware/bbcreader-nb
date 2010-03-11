//
//  NetworkService.h
//  NYTReader
//
//  Created by Jae Han on 6/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUM_INDEX_HOLDER 2

//@class HTTPHelper;
@class HTTPUrlHelper;
@class XMLReader;
@class HTMLParser;
@class WebCacheService;
@class ArticleStorage;
@class LocalServer;
@class LocalServerManager;
@class FeedInformation;

typedef struct indexpath_holder_t {
	NSIndexPath *index;
	NSString *url;
} indexpath_holder_t;


@interface NetworkService : NSThread <UIAlertViewDelegate> {
	NSFileManager	*mainFileManager;
	//HTTPHelper		*httpService;
	//HTTPUrlHelper	*httpService;
	XMLReader		*xmlReader;
	HTMLParser		*htmlParser;
	WebCacheService *cacheService;
	ArticleStorage  *theArticleStorage;
	LocalServerManager		*theLocalServer;
	//NSRunLoop		*theRunLoop;
	
	BOOL			executing;
	BOOL			finished;
	BOOL			cancelled;
	BOOL			networkNotWorking;
	NSCondition		*doSomething;
	NSCondition		*waitForUI;
	NSLock			*protectFeed;
	
	BOOL			changeToLocalServerMode;
	NSInteger		numberOfDownloadedObjects;
	NSInteger		numberOfArticleDownload;
	NSInteger		numberOfCSSDownload;
	NSInteger		numberOfThumbDownload;
	NSIndexPath		*currentWebIndex;
	indexpath_holder_t indexHolder[NUM_INDEX_HOLDER];
	int				currentHolderIndex;
	
	BOOL			requireConnection;
	BOOL			offlineMode;
	BOOL			shouldCheckExpiration;
	BOOL			reachabilityTestLater;
	BOOL			continueRefreshArticles;
	BOOL			refreshCheck;
	BOOL			feedReplaced;
	BOOL			showedSlowWarning;
	BOOL			shouldReloadArticles;
	NSInteger		activeThreadCount;
	//NSHTTPCookieStorage *cookieStorage;
}

@property (nonatomic, assign) NSCondition *doSomething;
@property (assign) BOOL changeToLocalServerMode;			
@property (assign) NSInteger numberOfDownloadedObjects;
@property (assign) BOOL networkNotWorking;
@property (assign) BOOL requireConnection;
@property (assign) BOOL offlineMode;
@property (assign) NSLock *protectFeed;
@property (assign) NSInteger activeThreadCount;

+(NetworkService*) sharedNetworkServiceInstance;

- (void)getArticlePage;
- (void)cleanNetworkThread;
- (BOOL)selectArticleAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)getNextActiveFeed;
//- (void)startLocalServer;
//- (void)stopLocalServer;
//- (HTTPUrlHelper*)requestWithURLUseCache:(NSString*)orig_url responseHeader:(NSData**)header responseBody:(NSData**)body toReleaseHeader:(BOOL*)release;
//- (HTTPUrlHelper*)requestWithURL:(NSString*)orig_url fileToSave:(NSString*)file responseHeader:(NSData**)header responseBody:(NSData**)body toReleaseHeader:(BOOL*)release;
//- (void)finishConnection;
- (BOOL)checkDiskSpace:(NSString*)directory;
- (void)displayDiskWarning;
- (BOOL)getCSS;
- (void)checkDownloadStatus;
- (void)setCurrentWebIndex:(NSIndexPath*)indexPath;
- (NSIndexPath*)getIndexForURL:(NSString*)url;
- (BOOL)testReachability;
- (void)getArticlePageInParallel;
//- (void)articleTask1;
- (void)articleTask2;
- (void)articleTask3;
- (void)articleTask4;
- (void)articleTask5;
- (void)articleTask6;
//- (BOOL)getNextArticleOfActiveFeed1;
//- (BOOL)getNextArticleOfActiveFeed2;
//- (BOOL)getNextArticleOfActiveFeed3;
//- (BOOL)getNextArticleOfActiveFeed4;
- (HTMLParser*)getHtmlParser;
- (void)refreshFeed:(FeedInformation*)feedInfo withIndex:(int)index;
- (void)cleanFeeds;
- (void)reloadArticles;

@end
