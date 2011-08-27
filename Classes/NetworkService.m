//
//  NetworkService.m
//  NYTReader
//
//  Created by Jae Han on 6/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include <pthread.h>
#include <sys/param.h>
#include <sys/mount.h>

#import "MReader_Defs.h"
#import "NetworkService.h"
#import "XMLReader.h"
//#import "HTTPHelper.h"
#import "HTMLParser.h"
#import "HTTPUrlHelper.h"
#import "FeedInformation.h"
#import "ArticleStorage.h"
#import "FeedStorage.h"
#import "WebLink.h"
#import "WebCacheService.h"
#import "ThumbNailHolder.h"
#import "Configuration.h"
#import "LocalServer.h"
#import "LocalServerManager.h"
#import "FeedStorage.h"

#import <SystemConfiguration/SystemConfiguration.h>

#define MIN_SPACE_FOR_MREADER			26214400
#define NUMBER_OF_ARTICLE_IN_TABLE		4
#define SLOW_NETWORK_INTERVAL			30
#define NUMBER_OF_THREAD				4

//NSString *rssfeedFilename = @"main_rss.xml";
//NSString *mainURLString = @"http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml";

static NetworkService *sharedNetworkService = nil;

//pthread_mutex_t network_mutex;

@implementation NetworkService

@synthesize doSomething;
@synthesize changeToLocalServerMode;
@synthesize numberOfDownloadedObjects;
@synthesize networkNotWorking;
@synthesize requireConnection;
@synthesize offlineMode;
@synthesize protectFeed;
@synthesize activeThreadCount;

/*
+ (void)initialize 
{

	FeedInformation *feedMain = [[FeedInformation alloc] initWithFeedInformation:@"main_rss.xml" 
																		 origURL:@"http://newsrss.bbc.co.uk/rss/newsonline_world_edition/front_page/rss.xml"];
								 //@"http://feeds.newyorker.com/services/rss/feeds/everything.xml"];
								 //"http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml"];
	FeedInformation *feedBusiness = [[FeedInformation alloc] initWithFeedInformation:@"business_rss.xml"
											 origURL:@"http://newsrss.bbc.co.uk/rss/newsonline_world_edition/business/rss.xml"];
								//@"http://feeds.newyorker.com/services/rss/feeds/reporting.xml"];
								//"http://www.nytimes.com/services/xml/rss/nyt/Business.xml"];
	
		//feedInformationStorage = [[NSArray alloc] initWithObjects:feedMain, feedBusiness, nil];
}
 */

+(NetworkService*) sharedNetworkServiceInstance 
{
	@synchronized (self) {
		if (sharedNetworkService == nil) {
			[[self alloc] init];
		}
	}
	return sharedNetworkService;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedNetworkService == nil) { 
			sharedNetworkService = [super allocWithZone:zone]; 
			return sharedNetworkService; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}


-(id)init {
	self = [super init];
	if (self) {
		executing = NO;
		finished = NO;
		cancelled = NO;
		
		mainFileManager = [NSFileManager defaultManager];
		//httpService = [[HTTPUrlHelper alloc] init];
		xmlReader = [[XMLReader alloc] init];
		htmlParser = [[HTMLParser alloc] init];
		cacheService = [WebCacheService sharedWebCacheServiceInstance];
		theArticleStorage = [ArticleStorage sharedArticleStorageInstance];	
		doSomething = [[NSCondition alloc] init];
		waitForUI = [[NSCondition alloc] init];
		protectFeed = [[NSLock alloc] init];
		changeToLocalServerMode = NO;
		//pthread_mutex_init(&network_mutex, NULL);
		theLocalServer = [[LocalServerManager alloc] init];
		numberOfDownloadedObjects = 0;
		numberOfArticleDownload = 0;
		numberOfCSSDownload = 0;
		numberOfThumbDownload = 0;
		currentWebIndex = nil;
		currentHolderIndex = 0;
		shouldCheckExpiration = NO;
		reachabilityTestLater = NO;
		for (int i=0; i<NUM_INDEX_HOLDER; ++i) {
			indexHolder[i].index = nil;
			indexHolder[i].url = nil;
		}
		continueRefreshArticles = YES;
		feedReplaced = NO;
		activeThreadCount = NUMBER_OF_THREAD;
		
		//cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		//[cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyNever];
	}
	
	return self;
}

-(BOOL)isCancelled {
	return cancelled;
}

-(BOOL)isExecuting {
	return executing;
}

-(BOOL)isFinished {
	return finished;
}

-(void)cancel {
	cancelled = YES;
}

- (BOOL)checkDiskSpace:(NSString*)directory
{
	BOOL ret = NO;
	struct statfs buf;
	
	if (statfs([directory UTF8String], &buf) < 0) {
		NSLog(@"%s, %s", __func__, strerror(errno));
		return YES; // assume success if this fails to get somehow. 
 	}
	
	NSUInteger free_space = buf.f_bsize * buf.f_bfree;
	NSLog(@"Free space: %u", free_space);
	
	if (free_space >= MIN_SPACE_FOR_MREADER)
		ret = YES;
	
	return ret;
}

- (void)displayDiskWarning
{
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(displayDiskWarning:) withObject:nil	waitUntilDone:YES];	
}

- (BOOL)testReachability
{
	Boolean success;
	Boolean isDataSourceAvailable;
	int i = 0;
	//NSURLResponse* theResponse = nil;
	//NSError* theError = nil;
	//NSMutableURLRequest *theRequest;
	const char* host_name = "www.apple.com";
	
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host_name);
	SCNetworkReachabilityFlags flags;

	success = SCNetworkReachabilityGetFlags(reachability, &flags);
	
	isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
	++i;

	CFRelease(reachability);

	NSLog(@"%s, %d, 0x%x, available: %d", __func__, success, flags, isDataSourceAvailable);
	
	requireConnection = success && (flags & kSCNetworkFlagsConnectionRequired);
	
	//if (isDataSourceAvailable == NO && (flags & kSCNetworkFlagsConnectionRequired)) {
	//	TRACE("%s, try different way.\n",__func__);
	//	theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]
	//											  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
	//										  timeoutInterval:60.0];
		
	//	[theRequest addValue:@"Mozilla/5.0 (iPhone Simulator; U; CPU iPhone OS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20" forHTTPHeaderField:@"User-Agent"];
		//[theRequest addValue:@"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" forHTTPHeaderField:@"Accept"];
		
	//	NSData *data = [NSURLConnection sendSynchronousRequest:(NSURLRequest*)theRequest returningResponse:&theResponse error:&theError];
	//	if (data == nil) {
	//		NSLog(@"%s, error in the connection: %@", __func__, [theError localizedDescription]);
	//	}
		
		//success = SCNetworkReachabilityGetFlags(reachability, &flags);
		//TRACE("%s again, %d, 0x%x\n", __func__, success, flags);
		
	//}
	
	
	return isDataSourceAvailable;
}


-(void)main {
	HTTPUrlHelper* helper;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"Network thread started:\n");
	executing = YES;
	
	//theRunLoop = [NSRunLoop currentRunLoop];
	
	[theLocalServer start];
	networkNotWorking = NO;
	
	@try {
		
		if (offlineMode == NO)
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		// Thread work goes here
		/* TODO: Network thread
		 *    Network thread is responsible to get any xml feed or HTML or embedded objects.
		 *    Should work like this:
		 *      1. Get feed if there is any.
		 *      2. If the feed is done, download each article in the feed,
		 *         and parse to get a thumbnail.
		 *      3. If a thumbnail is available, then get it first. 
		 *      4. If everything above is done, download embedded objects. 
		 *      5. Whild doing any of above, xml feed is avaiable, then get that first. 
		 */
		NSString *tmpDir = (NSString*) NSHomeDirectory();
		//NSError *parseError = nil;
		if (tmpDir == nil) {
			NSLog(@"%s, can't get the temporary directory.", __func__);
			return;
		}
		//if ([self checkDiskSpace:tmpDir] == NO) {
		//	[self displayDiskWarning];
		//}
		
		Configuration *config = [Configuration sharedConfigurationInstance];
		
		// Get the host first from the feed
		NSString *host = [theArticleStorage getHost]; 
		[cacheService initCacheObjects:host];
		
		[theArticleStorage initSegmentIndex:[config indexes]];
		
		if ([cacheService loadCacheObjectsFromCategory:CACHE_FEED] <= 1) {
#ifdef RUN_REACHABILITY
			[self testReachability];
#endif
		}
		else {
			reachabilityTestLater = YES;
		}
		if ([cacheService loadCacheObjectsFromCategory:CACHE_HTML] == 0) {
			refreshCheck = NO;
		}
		else {
			refreshCheck = YES;
		}
		
		shouldReloadArticles = NO;
		
#ifndef RUN_REACHABILITY
		// run with apple sdk first always
		requireConnection = YES;
#endif
		/*
		 * This is only for the url testing.
		 * If there is some URL causing some problem, you can test here.
		 */
		//NSURL *testURL = [[NSURL alloc] initWithString:@"http://news.bbc.co.uk/go/rss/-/2/hi/americas/7647986.stm"];
		//[httpService requestWithURLUseCache:testURL delegate:htmlParser parserKind:MREADER_HTML_PARSER feedIndex:nil shouldWait:YES];
		//goto clean;
		//
		//
		
		FeedInformation *feed = nil;
		// Get the feed first.
		int i = 0;
		
		//pthread_mutex_lock(&network_mutex);
		if ((feed = [theArticleStorage getNextFeedToRetrieve:&i]) != nil) {
			//feed = [feedInformationStorage objectAtIndex:i];
			//mainDocLoc = [tmpDir stringByAppendingPathComponent:feed.localFileName];
			//NSLog(@"Path to rss: %@", mainDocLoc);
			TRACE("%s, feed url: %s, index: %d\n", __func__, [feed.origURL UTF8String], i);
			// TODO: call rss parser with URL
			
			NSURL *mainURL = [[NSURL alloc] initWithString:feed.origURL];
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:i];
			
			helper = [[HTTPUrlHelper alloc] init];
			[helper requestWithURLUseCache:mainURL delegate:xmlReader parserKind:MREADER_XML_PARSER feedIndex:indexPath shouldWait:YES];
			if (helper) {
				feed.localFileName = [helper getCachedName];
				[helper release];
			}
		}
		//pthread_mutex_unlock(&network_mutex);
		// TODO: check network accessability here
		TRACE("Number of article available: %d\n", theArticleStorage.numberOfArticles);
		
		if (theArticleStorage.numberOfArticles == 0) {
			if (offlineMode == YES) {
				[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showOfflineModeWarning:) withObject:nil waitUntilDone:YES];
			}
			else {
				[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showNetworkError:) withObject:nil waitUntilDone:YES];
			}
		}
		else {
			numberOfDownloadedObjects = 1;
		
			// Now we want to get individual page. 
			//[self getArticlePage];
			[self getArticlePageInParallel];
		}
		
	}
	@catch (NSException *exception) {
		NSLog(@"NetworkService: main: %@: %@", [exception name], [exception reason]);
	}
	//@finally {
	//	<#handler#>
	//}
	
	// Even though it has exception or an error so we can't continue, we will wait here until user exits.
	do {
		[doSomething lock];
		networkNotWorking = YES;
		[doSomething wait];
		[doSomething unlock];
	} while (YES);
	
clean:
	NSLog(@"Ending network thread: %@", [pool description]);
	[self cleanNetworkThread];
	[pool release];
}

- (void)cleanNetworkThread
{
	// TODO: Need to find out how to clean this guys
	[ArticleStorage releaseArticles];
	[ThumbNailHolder releaseThumbNails];
	[WebCacheService releaseCacheObject];	
}

- (BOOL)getNextActiveFeed
{
	BOOL ret = NO;
	FeedInformation *feed = nil;
	int i = 0;
	HTTPUrlHelper* helper;

	if ((feed = [theArticleStorage getNextFeedToRetrieve:&i]) != nil) {
		TRACE("----> %s, feed url: %s, index: %d\n", __func__, [feed.origURL UTF8String], i);
		NSURL *mainURL = [[NSURL alloc] initWithString:feed.origURL];
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:i];
		TRACE("getNextActiveFeed: %d\n", i);
		helper = [[HTTPUrlHelper alloc] init];
		if ([helper requestWithURLUseCache:mainURL delegate:xmlReader parserKind:MREADER_XML_PARSER feedIndex:indexPath shouldWait:YES] == NO) {
			networkNotWorking = YES;
			[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showNetworkError:) withObject:nil waitUntilDone:YES];
			[theArticleStorage setToActive:NO withIndex:i];
			ret = NO;
		}
		else {
			networkNotWorking = NO;
			numberOfDownloadedObjects++;
			ret = YES;
		}
		
		feed.localFileName = [helper getCachedName];
		[helper release];
		//[mainURL release];
	}
	
	return ret;
}

- (BOOL)getNextArticleOfActiveFeed
{
	NSURL *url = nil;
	NSIndexPath *indexPath = nil;
	HTTPUrlHelper *helper = nil;
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getNextArticleOfActiveFeed:&indexPath];
	
	if (link == nil)
		return NO;
	
	url = [[NSURL alloc] initWithString:link.url];
	//NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:currentIndex];
	TRACE("++++++> %s, %s\n", __func__, [link.url UTF8String]);
	helper = [[HTTPUrlHelper alloc] init];
	if ([helper requestWithURLUseCache:url delegate:htmlParser parserKind:MREADER_HTML_PARSER feedIndex:indexPath shouldWait:YES] == YES) {
		numberOfDownloadedObjects++;
		numberOfArticleDownload++;
	}
	[helper release];
	link.isAvailable = YES;
	//[url release];
	return YES;
}

/*
- (BOOL)getNextArticleOfActiveFeed1
{
	NSURL *url = nil;
	NSIndexPath *indexPath = nil;
	HTTPUrlHelper *helper = nil;
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getNextArticleOfActiveFeed:&indexPath];
	
	if (link == nil)
		return NO;
	
	url = [[NSURL alloc] initWithString:link.url];
	//NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:currentIndex];
	TRACE("++++++> %s, %s\n", __func__, [link.url UTF8String]);
	helper = [[HTTPUrlHelper alloc] init];
	if ([helper requestWithURLUseCache:url delegate:htmlParser parserKind:MREADER_HTML_PARSER feedIndex:indexPath shouldWait:YES] == YES) {
		numberOfDownloadedObjects++;
		numberOfArticleDownload++;
	}
	[helper release];
	link.isAvailable = YES;
	return YES;
}

- (BOOL)getNextArticleOfActiveFeed2
{
	NSURL *url = nil;
	NSIndexPath *indexPath = nil;
	HTTPUrlHelper *helper = nil;
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getNextArticleOfActiveFeed:&indexPath];
	
	if (link == nil)
		return NO;
	
	url = [[NSURL alloc] initWithString:link.url];
	//NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:currentIndex];
	TRACE("++++++> %s, %s\n", __func__, [link.url UTF8String]);
	helper = [[HTTPUrlHelper alloc] init];
	if ([helper requestWithURLUseCache:url delegate:htmlParser parserKind:MREADER_HTML_PARSER feedIndex:indexPath shouldWait:YES] == YES) {
		numberOfDownloadedObjects++;
		numberOfArticleDownload++;
	}
	[helper release];
	link.isAvailable = YES;
	return YES;
}

- (BOOL)getNextArticleOfActiveFeed3
{
	NSURL *url = nil;
	NSIndexPath *indexPath = nil;
	HTTPUrlHelper *helper = nil;
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getNextArticleOfActiveFeed:&indexPath];
	
	if (link == nil)
		return NO;
	
	url = [[NSURL alloc] initWithString:link.url];
	//NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:currentIndex];
	TRACE("++++++> %s, %s\n", __func__, [link.url UTF8String]);
	helper = [[HTTPUrlHelper alloc] init];
	if ([helper requestWithURLUseCache:url delegate:htmlParser parserKind:MREADER_HTML_PARSER feedIndex:indexPath shouldWait:YES] == YES) {
		numberOfDownloadedObjects++;
		numberOfArticleDownload++;
	}
	[helper release];
	link.isAvailable = YES;
	return YES;
}

- (BOOL)getNextArticleOfActiveFeed4
{
	NSURL *url = nil;
	NSIndexPath *indexPath = nil;
	HTTPUrlHelper *helper = nil;
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getNextArticleOfActiveFeed:&indexPath];
	
	if (link == nil)
		return NO;
	
	url = [[NSURL alloc] initWithString:link.url];
	//NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:currentIndex];
	TRACE("++++++> %s, %s\n", __func__, [link.url UTF8String]);
	helper = [[HTTPUrlHelper alloc] init];
	if ([helper requestWithURLUseCache:url delegate:htmlParser parserKind:MREADER_HTML_PARSER feedIndex:indexPath shouldWait:YES] == YES) {
		numberOfDownloadedObjects++;
		numberOfArticleDownload++;
	}
	[helper release];
	link.isAvailable = YES;
	return YES;
}
 */

- (BOOL)getCSS
{
	
	if ([cacheService.cssDictionary count] == 0) {
		return NO;
	}
	
	HTTPUrlHelper *helper = nil;
	
	NSEnumerator *enumerator = [cacheService.cssDictionary keyEnumerator];
	id key;
	NSString* localName;
	NSString* origURL;
	
	key = [enumerator nextObject];
	if (key == nil) 
		return NO;
	
	origURL = (NSString*) [cacheService.cssDictionary objectForKey:key];
	localName = (NSString*) key;
	NSURL* url = [[NSURL alloc] initWithString:origURL]; 
	TRACE("++++++ Download css: %s, %d\n", [origURL UTF8String], [cacheService.cssDictionary count]);
	helper = [[HTTPUrlHelper alloc] init];
	if ([helper requestWithURL:url fileToSave:localName parserKind:MREADER_FILE_TYPE feedIndex:nil shouldWait:YES] == YES) {
		numberOfDownloadedObjects++;
		numberOfCSSDownload++;
	}

	[cacheService.cssDictionary removeObjectForKey:key];
	
	[helper release];
	[url release];
	if ([cacheService.cssDictionary count] == 0) 
		return NO;
	
	return YES;
}

- (BOOL)getThumbnail
{
	BOOL ret = NO;
	thumb_nail_object_t *thumbnail = nil;
	HTTPUrlHelper *helper = nil;
	
	if ((thumbnail = [ThumbNailHolder getThumbnail])) {
		if ([cacheService hasThisFile:thumbnail.local_name atIndex:thumbnail.indexPath] == NO) {
			// get a url and save to a file.
			// and tell that to tableview.
			// we will do this first if there is an entry for this.
			NSURL* url = [NSURL URLWithString:thumbnail.orig_url];
			helper = [[HTTPUrlHelper alloc] init];
			if ([helper requestWithURL:url fileToSave:thumbnail.local_name parserKind:MREADER_FILE_TYPE feedIndex:thumbnail.indexPath shouldWait:YES] == YES) {
				numberOfDownloadedObjects++;
				numberOfThumbDownload++;
			}
		}
		else {
			numberOfDownloadedObjects++;
			numberOfThumbDownload++;
		}
		
		[helper release];
		TRACE("======> getThumbnail: %s\n", [thumbnail.orig_url UTF8String]);
		//[thumbnail.local_name release];
		//[thumbnail.orig_url release];
		[thumbnail release];
		ret = YES;

	}
	
	return ret;
}

- (BOOL)getEmbeddedObjects
{
	return NO;
}

- (void)getArticlePage
{
	//FeedStorage* feed = [[ArticleStorage sharedArticleStorageInstance] getFeedStorageRefAtIndex:currentIndex];
	BOOL cont = NO;
	BOOL thumbNailCacheLoaded = NO;
	BOOL isPoolCreated = NO;
	NSAutoreleasePool *pool = nil;
	int articleCount = 0;
	//BOOL thumbNailGarbageCleaned = NO;
		
	do {
		TRACE("----- Start getting article pages ------\n");
		@try {
			do {
				if (isPoolCreated == YES) {
					[pool release];
					isPoolCreated = NO;
				}
				pool = [[NSAutoreleasePool alloc] init];
				isPoolCreated = YES;
				//link = [storage getNextArticleOfActiveFeed];
				TRACE(" ^^^^^^ Ready to run loop.\n");
				
				[self checkDownloadStatus];
				/*
				 if (((cont = [self getNextActiveFeed:storage]) == NO) &&
				 ((cont = [self getThumbnail]) == NO) &&
				 ((cont = [self getNextArticleOfActiveFeed:storage]) == NO)) {
				 cont = [self getEmbeddedObjects:storage];
				 }
				 */
				
				//if (changeToLocalServerMode == YES) continue;
				
				if (articleCount < NUMBER_OF_ARTICLE_IN_TABLE) {
					//pthread_mutex_lock(&network_mutex);
					cont = [self getThumbnail];
					//pthread_mutex_unlock(&network_mutex);
					if (changeToLocalServerMode == YES) {
						cont = NO;
						goto waitLoop;
					}
					if (cont == YES) continue;
					
					//pthread_mutex_lock(&network_mutex);
					cont = [self getNextArticleOfActiveFeed];
					articleCount++;
					//pthread_mutex_unlock(&network_mutex);
					if (changeToLocalServerMode == YES) {
						cont = NO;
						goto waitLoop;
					}
					
					if (thumbNailCacheLoaded == NO) {
						[cacheService loadCacheObjectsFromCategory:CACHE_THUMB_NAIL];
						thumbNailCacheLoaded = YES;
					}
					
					if (cont == YES) continue;
				}
				else {
					articleCount = 0;
					//pthread_mutex_lock(&network_mutex);
					cont = [self getNextActiveFeed];
					//pthread_mutex_unlock(&network_mutex);
					if (changeToLocalServerMode == YES) {
						cont = NO;
						goto waitLoop;
					}
					if (cont == YES)  continue;
					
					//pthread_mutex_lock(&network_mutex);
					cont = [self getThumbnail];
					//pthread_mutex_unlock(&network_mutex);
					if (changeToLocalServerMode == YES) {
						cont = NO;
						goto waitLoop;
					}
					if (cont == YES) continue;
					
					//pthread_mutex_lock(&network_mutex);
					cont = [self getNextArticleOfActiveFeed];
					//pthread_mutex_unlock(&network_mutex);
					if (changeToLocalServerMode == YES) {
						cont = NO;
						goto waitLoop;
					}
					
					
					if (thumbNailCacheLoaded == NO) {
						[cacheService loadCacheObjectsFromCategory:CACHE_THUMB_NAIL];
						thumbNailCacheLoaded = YES;
					}
					
					if (cont == YES) continue;
				}
				
				//pthread_mutex_lock(&network_mutex);
				cont = [self getCSS];
				//pthread_mutex_unlock(&network_mutex);
				if (changeToLocalServerMode == YES) {
					cont = NO;
					goto waitLoop;
				}
				
				if (cont == YES) continue;
				
				/* TODO: Do we need to load others???
				 if (othersCacheLoaded == NO) {
				 [cacheService loadCacheObjectsFromCategory:CACHE_NONE];
				 othersCacheLoaded = YES;
				 }
				 */
				//pthread_mutex_lock(&network_mutex);
				cont = [self getEmbeddedObjects];
				//pthread_mutex_unlock(&network_mutex);
				//if (changeToLocalServerMode == YES) [self startLocalServer];
				if (changeToLocalServerMode == YES) {
					cont = NO;
					goto waitLoop;
				}
				
				if (cont == YES) continue;
				
				
				//pthread_mutex_lock(&network_mutex);
				cont = [cacheService doGarbageCollection];
				//pthread_mutex_unlock(&network_mutex);
				if (changeToLocalServerMode == YES) {
					cont = NO;
					goto waitLoop;
				}
				
				if (cont == YES) continue;
				
				//if (thumbNailGarbageCleaned == NO) {
					//pthread_mutex_lock(&network_mutex);
					cont = [cacheService doGarbageCollectionForThumbnail];
					//pthread_mutex_unlock(&network_mutex);
					//thumbNailGarbageCleaned = YES;
					if (changeToLocalServerMode == YES) {
						cont = NO;
						goto waitLoop;
					}
				//}
				
				if (cont == YES) continue;
				
				// TODO: what is the best way of sleep and wakeup in this case.
				//       just looping here may not be such a good idea because 
				//       CPU utilization goes up 100%.
				//
				//if (i++ > 20) {
				//	sleep(5);
				//	break;
				//}
				
			waitLoop:
				[pool release];

				// TODO: predownload CSSs
				if (cont == NO) {
					TRACE("~~~~~~~~ Waiting to do something.\n");
					if (offlineMode == NO)
						[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
					[doSomething lock];
					[doSomething wait];
					[doSomething unlock];
					TRACE("~~~~~~~~ There is something to do.\n ");
					if (offlineMode == NO)
						[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
				}
			} while (YES);
		}
		@catch (NSException *exception) {
			NSLog(@"getArticlePage: main: %@: %@", [exception name], [exception reason]);
			//pthread_mutex_trylock(&network_mutex);
			//pthread_mutex_unlock(&network_mutex);
		}
	} while (YES);
}

- (void)getArticlePageInParallel
{
	BOOL cont = NO;
	BOOL thumbNailCacheLoaded = NO;
	
	if (thumbNailCacheLoaded == NO) {
		[cacheService loadCacheObjectsFromCategory:CACHE_THUMB_NAIL];
		thumbNailCacheLoaded = YES;
	}
	
	[NSThread detachNewThreadSelector:@selector(articleTask2) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(articleTask3) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(articleTask4) toTarget:self withObject:nil];
	//[NSThread detachNewThreadSelector:@selector(articleTask5) toTarget:self withObject:nil];
	//[NSThread detachNewThreadSelector:@selector(articleTask6) toTarget:self withObject:nil];
	
	
	for (;;) {
		[self checkDownloadStatus];
		
		/*
		if (isPoolCreated == YES) {
			[pool release];
			isPoolCreated = NO;
		}
		pool = [[NSAutoreleasePool alloc] init];
		isPoolCreated = YES;
		 */
				
		cont = [self getNextArticleOfActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		
		if (cont == YES) {
			[doSomething broadcast];
			continue;
		}
		
		cont = [self getNextActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) {
			[doSomething broadcast];
			continue;
		}
		
		//pthread_mutex_lock(&network_mutex);
		cont = [self getThumbnail];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) continue;
		
		if (shouldCheckExpiration == YES && activeThreadCount <= 1) {
			// Only when everything have been downloaded and no active thread except this one is running,
			// then run garbage collection.
			cont = [cacheService doGarbageCollection];
			//pthread_mutex_unlock(&network_mutex);
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
			
			cont = [cacheService doGarbageCollectionForThumbnail];
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
		}
		
	waitLoop:
		
#ifdef CHECK_LATER
		// TODO: should execute only when everything is done. 
		// 1. Download the first feed and check to see if it is not too slow.
		// 2. If user wants to continue, lock it up during the update.
		if (continueRefreshArticles == YES && offlineMode == NO && refreshCheck == YES && shouldCheckExpiration == YES) {
			// check expiration date of RSS feed and fetch them if necessrary.
			showedSlowWarning = NO;
			[self cleanFeeds];

			for (int i=0; i<3; ++i) {
				FeedInformation *feedInfo = [theArticleStorage getActiveFeed:i];
				if (shouldReloadArticles == YES) {
					TRACE(">>>>> %s, reload feed, %s\n", __func__, [feedInfo.origURL UTF8String]);
					[self refreshFeed:feedInfo withIndex:i];
				}
				else if ([cacheService checkExpiration:feedInfo.localFileName] == NO) {
					// feed is expired.
					TRACE(">>>>> %s, refresh feed, %s\n", __func__, [feedInfo.origURL UTF8String]);
					[self refreshFeed:feedInfo withIndex:i];
					shouldReloadArticles = YES;
				}
				if (continueRefreshArticles == NO) break;
			}
			refreshCheck = NO;
			shouldReloadArticles = NO;
			[doSomething broadcast];
			continue;
		}
#endif
		activeThreadCount--;
		[self checkDownloadStatus];
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		activeThreadCount++;
	}
	
}

- (void)reloadArticles
{
	shouldReloadArticles = YES;
	continueRefreshArticles = YES;
	refreshCheck = YES;
	shouldCheckExpiration = YES;
	[doSomething broadcast];
}

- (void)articleTask2
{
	BOOL cont = NO;
	
#ifdef RUN_REACHABILITY
	if (reachabilityTestLater == YES) {
		[self testReachability];
		reachabilityTestLater = NO;
	}
#endif
	
	for (;;) {
		[self checkDownloadStatus];
		
		/*
		if (isPoolCreated == YES) {
			[pool release];
			isPoolCreated = NO;
		}
		pool = [[NSAutoreleasePool alloc] init];
		isPoolCreated = YES;
		 */

		cont = [self getNextActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) {
			[doSomething broadcast];
			continue;
		}
		
		cont = [self getNextArticleOfActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		
		if (cont == YES) {
			[doSomething broadcast];
			continue;
		}
		
		cont = [self getCSS];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		
		if (cont == YES) continue;
		
		if (shouldCheckExpiration == YES && activeThreadCount <= 1) {
			// Only when everything have been downloaded and no active thread except this one is running,
			// then run garbage collection.
			cont = [cacheService doGarbageCollection];
			//pthread_mutex_unlock(&network_mutex);
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
			
			cont = [cacheService doGarbageCollectionForThumbnail];
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
		}
		 
		
	waitLoop:
		activeThreadCount--;
		[self checkDownloadStatus];
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		activeThreadCount++;
		
	}
}

- (void)articleTask3
{
	BOOL cont = NO;
	
	
	for (;;) {
		[self checkDownloadStatus];
		
		/*
		if (isPoolCreated == YES) {
			[pool release];
			isPoolCreated = NO;
		}
		pool = [[NSAutoreleasePool alloc] init];
		isPoolCreated = YES;
		 */
		
		cont = [self getThumbnail];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) continue;
		
		cont = [self getNextArticleOfActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}

		if (cont == YES) {
			[doSomething broadcast];
			continue;
		}
		
		if (shouldCheckExpiration == YES && activeThreadCount <= 1) {
			// Only when everything have been downloaded and no active thread except this one is running,
			// then run garbage collection.
			cont = [cacheService doGarbageCollection];
			//pthread_mutex_unlock(&network_mutex);
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
			
			cont = [cacheService doGarbageCollectionForThumbnail];
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
		}
		
		
	waitLoop:
		activeThreadCount--;
		[self checkDownloadStatus];
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		activeThreadCount++;
		
	}
}

- (void)articleTask4
{
	BOOL cont = NO;

	
	for (;;) {
		[self checkDownloadStatus];
		/*
		if (isPoolCreated == YES) {
			[pool release];
			isPoolCreated = NO;
		}
		pool = [[NSAutoreleasePool alloc] init];
		isPoolCreated = YES;
		 */
		
		//pthread_mutex_lock(&network_mutex);
		cont = [self getThumbnail];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) continue;
		
		cont = [self getNextArticleOfActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		
		if (cont == YES) continue;
		
		if (shouldCheckExpiration == YES && activeThreadCount <= 1) {
			// Only when everything have been downloaded and no active thread except this one is running,
			// then run garbage collection.
			cont = [cacheService doGarbageCollection];
			//pthread_mutex_unlock(&network_mutex);
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
			
			cont = [cacheService doGarbageCollectionForThumbnail];
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
		}
		
		
	waitLoop:
		activeThreadCount--;
		[self checkDownloadStatus];
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		activeThreadCount++;
		
	}
}

- (void)articleTask5
{
	BOOL cont = NO;

	
	for (;;) {
		[self checkDownloadStatus];
		
		//if (isPoolCreated == YES) {
		//	[pool release];
		//	isPoolCreated = NO;
		//}
		//pool = [[NSAutoreleasePool alloc] init];
		//isPoolCreated = YES;
		
		//pthread_mutex_lock(&network_mutex);
		cont = [self getThumbnail];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) continue;
		
		cont = [self getNextArticleOfActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		
		if (cont == YES) continue;
		
		if (shouldCheckExpiration == YES && activeThreadCount <= 1) {
			// Only when everything have been downloaded and no active thread except this one is running,
			// then run garbage collection.
			cont = [cacheService doGarbageCollection];
			//pthread_mutex_unlock(&network_mutex);
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
			
			cont = [cacheService doGarbageCollectionForThumbnail];
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
		}
		
		
	waitLoop:
		activeThreadCount--;
		[self checkDownloadStatus];
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		activeThreadCount++;
		
	}
}

- (void)articleTask6
{
	BOOL cont = NO;

	for (;;) {
		[self checkDownloadStatus];
		
		//if (isPoolCreated == YES) {
		//	[pool release];
		//	isPoolCreated = NO;
		//}
		//pool = [[NSAutoreleasePool alloc] init];
		//isPoolCreated = YES;
		
		//pthread_mutex_lock(&network_mutex);
		cont = [self getThumbnail];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		if (cont == YES) continue;
		
		cont = [self getNextArticleOfActiveFeed];
		//pthread_mutex_unlock(&network_mutex);
		if (changeToLocalServerMode == YES) {
			cont = NO;
			goto waitLoop;
		}
		
		if (cont == YES) continue;
		
		if (shouldCheckExpiration == YES && activeThreadCount <= 1) {
			// Only when everything have been downloaded and no active thread except this one is running,
			// then run garbage collection.
			cont = [cacheService doGarbageCollection];
			//pthread_mutex_unlock(&network_mutex);
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
			
			cont = [cacheService doGarbageCollectionForThumbnail];
			if (changeToLocalServerMode == YES) {
				cont = NO;
				goto waitLoop;
			}
			
			if (cont == YES) continue;
		}
		
		
	waitLoop:
		activeThreadCount--;
		[self checkDownloadStatus];
		[doSomething lock];
		[doSomething wait];
		[doSomething unlock];
		activeThreadCount++;
		
	}
}

- (void)checkDownloadStatus
{
	static NSInteger nArticle=0;
	static NSInteger nImage=0;
	static NSInteger nChannel=0;
	static NSInteger nCSS = 0;
	static NSInteger nDownload = 0;
	BOOL shouldNotify = NO;
	
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	if (nArticle != storage.numberOfArticles) {
		nArticle = storage.numberOfArticles;
		shouldNotify = YES;
	}
	
	if (nImage != storage.numberOfImages) {
		nImage = storage.numberOfImages;
		shouldNotify = YES;
	}
	
	if (nChannel != storage.numberOfChannel) {
		nChannel = storage.numberOfChannel;
		shouldNotify = YES;
	}
	
	if (nCSS != cacheService.numberOfCSSs) {
		nCSS = cacheService.numberOfCSSs;
		shouldNotify = YES;
	}
	
	if (nDownload != numberOfDownloadedObjects) {
		nDownload = numberOfDownloadedObjects;
		shouldNotify = YES;
	}
	
	if (nDownload >= (nArticle+nImage+nCSS+nChannel)) 
	{
		shouldCheckExpiration = YES;
	}
	
	//if (shouldNotify == YES) {
	//	TRACE("Status: a: %d t: %d c: %d\n", numberOfArticleDownload, numberOfThumbDownload, numberOfCSSDownload);
	//	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateDownloadStatus:) withObject:nil waitUntilDone:YES];
	//}
}

- (BOOL)selectArticleAtIndexPath:(NSIndexPath*)indexPath
{
	BOOL ret = YES;
	
	//NSLog(@"%s", __func__);
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	[storage showArticle:indexPath];
	[doSomething broadcast];
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:nil	waitUntilDone:YES];
	
	return ret;
}

- (void)setCurrentWebIndex:(NSIndexPath*)indexPath
{
	currentHolderIndex = (currentHolderIndex + 1) % NUM_INDEX_HOLDER;
	
	indexHolder[currentHolderIndex].index = [theArticleStorage fillSelectedLink:indexPath];
	indexHolder[currentHolderIndex].url = [theArticleStorage getURLFromIndexPath:indexHolder[currentHolderIndex].index];
	TRACE("%s, row: %d, section: %d\n", __func__, indexHolder[currentHolderIndex].index.row, indexHolder[currentHolderIndex].index.section);
}

- (NSIndexPath*)getIndexForURL:(NSString*)url
{
	NSIndexPath *index = nil;
	
	for (int i=0; i<NUM_INDEX_HOLDER; ++i) {
		if (indexHolder[i].index != nil) {
			if ([url compare:indexHolder[i].url] == NSOrderedSame) {
				index = indexHolder[i].index;
				indexHolder[i].index = nil;
				return index;
			}
		}
	}
	
	return index;
}

- (HTMLParser*)getHtmlParser
{
	return htmlParser;
}

- (void)cleanFeeds
{
	// Clean thumbnail storage.
	[ThumbNailHolder releaseThumbNails];
	ThumbNailHolder *storage = [ThumbNailHolder sharedThumbNailHolderInstance];
	storage.theCurrentIndex = 0;
}

- (void)refreshFeed:(FeedInformation*)feedInfo withIndex:(int)index
{
	NSData *header = nil;
	NSData *body = nil;
	BOOL release = NO;
	BOOL shouldCleanLater = NO;
	
	if (feedInfo == nil)
		return;
	
	NSURL *mainURL = [[NSURL alloc] initWithString:feedInfo.origURL];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[theArticleStorage getActiveFeedIndex:index]];
	TRACE("%s: %d\n", __func__, index);
	
	// Get a new feed, when the new feed is available, we will replace the old to new. 
	// While replacing, the feed will be locked. 
	time_t before = time(nil);
	HTTPUrlHelper* helper = [[HTTPUrlHelper alloc] init];
	[helper ignoreCache:YES];
	[helper notifyReloadXML:NO];
	if ([helper requestWithURLUseCache:mainURL delegate:xmlReader parserKind:MREADER_XML_PARSER feedIndex:indexPath shouldWait:NO] == YES) {
		time_t after = time(nil);
		
		TRACE("%s, before: %d, after: %d\n", __func__, (int)before, (int)after);
		if (showedSlowWarning == NO && ((after - before) >= SLOW_NETWORK_INTERVAL)) {
			// show slow network warning
			[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(displaySlowNetworkWarning:) withObject:self	waitUntilDone:YES];	
			[waitForUI lock];
			[waitForUI wait];
			[waitForUI unlock];
			showedSlowWarning = YES;
		}
		
		NetworkService *networkService = [NetworkService sharedNetworkServiceInstance];
		if (continueRefreshArticles == YES) {
			TRACE("%s, refresh feeds.\n", __func__);
			// this has to be protected.
			ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];

						
			// 
			[protectFeed lock];
			FeedStorage *feed = [theArticleStorage getActiveFeedStorage:index];
			
			if (networkService.numberOfDownloadedObjects > 0)
				networkService.numberOfDownloadedObjects -= [feed.rssFeeds count];
			if (storage.numberOfArticles > 0)
				storage.numberOfArticles -= [feed.rssFeeds count];
		    storage.numberOfChannel--;

			[feed release];
			[theArticleStorage cleanActiveFeedStorage:index];
			
			// TODO: Potential issue that the parser can only kick in for newly downloaded object.
			// Hack: for parser to work later.
			helper.isLocalRequest = NO;
			shouldCleanLater = [helper constructResponseWithHeader:&header withBody:&body toReleaseHeader:&release];
			
			[protectFeed unlock];
			//
		}
		else {
			networkService.offlineMode = YES;
		}
	}
	else {
		// network error, don't continue.
		continueRefreshArticles = NO;
	}
			
	if (shouldCleanLater == YES) {
		[helper finishConnection];
		[helper release];
		
		if (release == YES) {
			[header release];
			[body release];
		}
		
	}
	else {
		[helper release];
	}

	
	
	
	
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	TRACE("%s, index: %d\n", __func__, buttonIndex);
	if (buttonIndex == 0) {
		// continue update
		continueRefreshArticles = YES;
		[waitForUI signal];
	}
	else {
		// stop
		continueRefreshArticles = NO;
		[waitForUI signal];
	}
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


- (void)dealloc {
	//[httpService release];
	[xmlReader release];
	[htmlParser release];
	[super dealloc];
}

@end
