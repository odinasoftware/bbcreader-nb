//
//  ArticleStorage.m
//  NYTReader
//
//  Created by Jae Han on 7/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "ArticleStorage.h"
#import "FeedStorage.h"
#import "WebLink.h"
#import "FeedInformation.h"
#import "NetworkService.h"
#import "SelectedSegmentIndex.h"
#import "Configuration.h"
#import "WebCacheService.h"

#define MAX_TITLE_LEN 14
#define MAX_HEADER_LEN 30

#define MAX_TRY_COUNT 3

static ArticleStorage *sharedArticleStorage = nil;
static int currentFeedIndex = -1;

NSString *getTitleString(NSArray* storage, int index)
{
	NSString *str = nil;
	FeedInformation* feed = [storage objectAtIndex:index];
	str = feed.title;
	if ([str length]> MAX_TITLE_LEN) {
		str = [str substringToIndex:MAX_TITLE_LEN-3];
		str = [str stringByAppendingFormat:@"..."];
	}
	return str;
}

NSString *getTitle(NSString *str)
{
	if ([str length]> MAX_HEADER_LEN) {
		str = [str substringToIndex:MAX_HEADER_LEN-3];
		str = [str stringByAppendingFormat:@"..."];
	}
	return str;
}

@implementation ArticleStorage

@synthesize contentsArray;
@synthesize currentFeedStorage;
@synthesize theActiveFeed;
@synthesize feedInformationStorage;
@synthesize articleSize;
@synthesize FeedsArray;
@synthesize numberOfImages;
@synthesize numberOfArticles;
@synthesize numberOfChannel;

+(ArticleStorage*) sharedArticleStorageInstance 
{
	@synchronized (self) {
		if (sharedArticleStorage == nil) {
			[[self alloc] init];
		}
	}
	return sharedArticleStorage;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedArticleStorage == nil) { 
			sharedArticleStorage = [super allocWithZone:zone]; 
			return sharedArticleStorage; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

+ (void)addArticle:(WebLink*)article atIndex:(NSInteger)index
{
	ArticleStorage* sharedStorage = [ArticleStorage sharedArticleStorageInstance];
	@synchronized (sharedStorage) {
		//if (currentFeedIndex < index) {
		if (sharedStorage.contentsArray[index] == nil) {
			TRACE("prepare new storage: index: %d\n", index);
			// We haven't prepared for this feed index,
			// will need to create one for this.
			FeedStorage *newsFeed = [[FeedStorage alloc] init];
			sharedStorage.contentsArray[index] = newsFeed;
			sharedStorage.currentFeedStorage = newsFeed;
			currentFeedIndex = index;
		}
		
		[sharedStorage.currentFeedStorage.rssFeeds addObject:article];
		sharedStorage.numberOfArticles++;
	}
	//TRACE("++++ addArticle: %s, %d, total: %d\n", [article.url UTF8String], index, [sharedStorage.currentFeedStorage.rssFeeds count]);
}

+ (void)setImageLink:(NSString*)imageFile atIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath == nil)
		return;
	
	ArticleStorage* sharedStorage = [ArticleStorage sharedArticleStorageInstance];
	
	@synchronized (sharedStorage) {
		FeedStorage* feed = sharedStorage.contentsArray[indexPath.section];
		if (feed != nil) {
			//@synchronized(self) {
			WebLink *link = [feed.rssFeeds objectAtIndex:indexPath.row];
			if (link != nil) {
				link.imageLink = imageFile;
				TRACE("setImageLink: %s, (%d, %d)\n", [imageFile UTF8String], indexPath.section, indexPath.row);
				sharedStorage.numberOfImages++;
				[WebCacheService removeThisFromGarbage:[imageFile lastPathComponent]];
				[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateImageLink:) withObject:(id)nil waitUntilDone:YES];
			}
			else {
				NSLog(@"%s, can't find link at: %d", __func__, indexPath.row);
			}
			//}
		}
		else {
			NSLog(@"%s, can't find feed at: %d", __func__, indexPath.section);
		}
	}
}

+(void) addChannel:(WebLink*)channel atIndex:(NSInteger)index
{
	TRACE("addChannel: title: %s, at: %d\n", [channel.text UTF8String], index);
	
	ArticleStorage* sharedStorage = [ArticleStorage sharedArticleStorageInstance];
	@synchronized (sharedStorage) {
		//if (currentFeedIndex < index) {
		if (sharedStorage.contentsArray[index] == nil) {
			TRACE("prepare new storage in channel: index: %d\n", index);
			// We haven't prepared for this feed index,
			// will need to create one for this.
			FeedStorage *newFeed = [[FeedStorage alloc] init];
			newFeed.titleForFeed = channel.text;
			[channel release];
			sharedStorage.contentsArray[index] = newFeed;
			sharedStorage.currentFeedStorage = newFeed;
			currentFeedIndex = index;		
			sharedStorage.numberOfChannel++;
		}
		//else if (currentFeedIndex > index) {
		//	NSLog(@"%s, index error in channel: %d", __func__, index);
		//	return;
		//}
		else {
			sharedStorage.currentFeedStorage.titleForFeed = channel.text;
			[channel release];
		}
	}
}

+ (void)setChannelBuildDate:(NSString*)date atIndex:(NSInteger)index
{
	TRACE("set build date: %s at %d\n", [date UTF8String], index);
	
	ArticleStorage* sharedStorage = [ArticleStorage sharedArticleStorageInstance];
	@synchronized (sharedStorage) {
		if (sharedStorage.contentsArray[index] == nil) {
			TRACE("prepare new storage in channel: index: %d\n", index);
			// We haven't prepared for this feed index,
			// will need to create one for this.
			FeedStorage *newFeed = [[FeedStorage alloc] init];
			NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
			newFeed.buildDate = [dateFormater dateFromString:date];
			[dateFormater release];
			sharedStorage.contentsArray[index] = newFeed;
			sharedStorage.currentFeedStorage = newFeed;
			currentFeedIndex = index;		
		}
		else {
			NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
			sharedStorage.currentFeedStorage.buildDate = [dateFormater dateFromString:date];
			[dateFormater release];
		}
		[date release];
	}
	
}

+ (void)setChannelTTL:(NSInteger)ttl atIndex:(NSInteger)index
{
	ArticleStorage* sharedStorage = [ArticleStorage sharedArticleStorageInstance];
	
	@synchronized (sharedStorage) {
		TRACE("set ttl : %d at: %d\n", ttl, index);
		
		if (sharedStorage.currentFeedStorage == nil || sharedStorage.contentsArray[index] == nil) {
			NSLog(@"Current channel is nil at %d", index);
			return;
		}
		
		sharedStorage.currentFeedStorage.ttl = ttl;
	}
}

- (id)init 
{
	if ((self = [super init])) {
		//contentsArray = [[NSMutableArray alloc] init];
		theActiveFeed = 0;
		NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"Feeds" ofType:@"plist"];
		FeedsArray= [[NSArray alloc] initWithContentsOfFile:thePath];
		
		thePath = [[NSBundle mainBundle]  pathForResource:@"Sports" ofType:@"plist"];
		sportFeedsArray = [[NSArray alloc] initWithContentsOfFile:thePath];
		
		thePath = [[NSBundle mainBundle]  pathForResource:@"mobile" ofType:@"plist"];
		mobileFeedsArray = [[NSArray alloc] initWithContentsOfFile:thePath];
		
		networkService = [NetworkService sharedNetworkServiceInstance];
		//thePath = [[NSBundle mainBundle]  pathForResource:@"InternationalFeeds" ofType:@"plist"];
		//internationalFeedsArray = [[NSArray alloc] initWithContentsOfFile:thePath];
		
		toGetActiveFeed = YES;
		articleSize = [FeedsArray count];
		
		// get the feed
		feedInformationStorage = [[NSMutableArray alloc] initWithCapacity:articleSize*2];
		//feedInformationStorage1 = [[NSMutableArray alloc] initWithCapacity:[sportFeedsArray count]];
		//feedInformationStorage2 = [[NSMutableArray alloc] initWithCapacity:[internationalFeedsArray count]];
		FeedInformation *feed;
		int i = 0;
		feedBegin[0] = i;
		for (NSDictionary *entry in FeedsArray) {
			for (NSString *key in entry) {
				feed = [[FeedInformation alloc] initWithFeedInformation:key origURL:[entry objectForKey:key]];
				[feedInformationStorage insertObject:feed atIndex:i]; i++;
			}
		}
		
		feedBegin[1] = i;
		for (NSDictionary *entry in mobileFeedsArray) {
			for (NSString *key in entry) {
				feed = [[FeedInformation alloc] initWithFeedInformation:key origURL:[entry objectForKey:key]];
				[feedInformationStorage insertObject:feed atIndex:i]; i++;
			}
		}
		
		feedBegin[2] = i;
		for (NSDictionary *entry in sportFeedsArray) {
			for (NSString *key in entry) {
				feed = [[FeedInformation alloc] initWithFeedInformation:key origURL:[entry objectForKey:key]];
				[feedInformationStorage insertObject:feed atIndex:i]; i++;
			}
		}
		/*
		feedBegin[2] = i;
		for (NSDictionary *entry in internationalFeedsArray) {
			for (NSString *key in entry) {
				feed = [[FeedInformation alloc] initWithFeedInformation:key origURL:[entry objectForKey:key]];
				[feedInformationStorage insertObject:feed atIndex:i]; i++;
			}
		}
		 */
		articleSize = i;
		[self setArticleSize:articleSize];
		for (i=0; i<ACTIVE_FEED_NUM; ++i) {
			activeFeed[i] = i;
		}
		
		contentsArray = (id*) malloc(sizeof(id)*articleSize);
		for (i=0; i<articleSize; ++i) {
			contentsArray[i] = nil;
		}
		
		theActiveFeedOfSegmentControl = theCurrentFeedSegmentIndex = -1;
		theCurrentArticleIndex = 0;
		// This will be always the last index for others navigation.
		theOtherIndex = ACTIVE_FEED_NUM-1;
		toGetActiveSegment = NO;
	
		imageStorage = [[NSMutableArray alloc] initWithCapacity:20];
		theCurrentSlide.section = theCurrentSlide.row = 0;
		theNavMode = ARTICLE_MAIN_NAV_MODE;
		numberOfImages = 0;
		numberOfArticles = 0;
		numberOfChannel = 0;
		activateOthers = NO;
	}
	
	return self;
}

- (NSInteger) numberOfFeedSections
{
	return 3; //[FeedsArray count] + [sportFeedsArray count] + [internationalFeedsArray count];
}

- (NSInteger)numberOfFeeds:(NSInteger)component 
{
	NSInteger c = 0;
	
	switch(component) {
		case 0:
			c = [FeedsArray count];
			break;
		case 1:
			c = [mobileFeedsArray count];
			break;
		case 2:
			c = [sportFeedsArray count];
			break;
			/*
		case 2:
			c = [internationalFeedsArray count];
			break;
			 */
	}
	
	return c;
}

- (NSString*)getSectionTitle:(NSInteger)row withComponent:(NSInteger)component bySelection:(NSInteger)selection
{
	NSString *title = nil;
	
	switch (component) {
		case 0:
			switch(row) {
				case 0:
					title = @"World news";
					break;
				case 1:
					title = @"Mobile";
					break;
				case 2:
					title = @"Sports";
					break;
					/*
				case 2:
					title = @"International";
					break;
					 */
			}
			break;
		case 1:
			if (articleSize > (feedBegin[selection]+row)) {
				title = getTitleString(feedInformationStorage, feedBegin[selection]+row);
			}
			else {
				NSLog(@"%s, index error. %d, %d, %d", __func__, articleSize, feedBegin[selection], row);
			}
			break;
		default:
			NSLog(@"%s, wrong component: %d", __func__, component);
	}
	return title	;
}

- (NSInteger)getArticleIndexWith:(NSInteger)row andSelection:(NSInteger)selection
{
	return feedBegin[selection] + row;
}

- (FeedInformation*)feedByIndexPath:(NSIndexPath*)index 
{
	FeedInformation *feed = nil;
	
	TRACE("%s, section: %d, row: %d\n", __func__, index.section, index.row);
	feed = [feedInformationStorage objectAtIndex:feedBegin[index.section] + index.row];
	
	return feed;
}

- (NSInteger)countInSection:(NSInteger)section
{
	NSInteger c = 0;
	
	if (section > NUM_FEED) {
		NSLog(@"%s, index error: %d", __func__, section);
		return 0;
	}
	
	if (section == 0) {
		c = feedBegin[1];
	}
	else if (section == 1) {
		c = feedBegin[section+1] - feedBegin[section];
	}
	else {
		c = articleSize - feedBegin[2];
	}
	
	return c;
}

- (void)initSegmentIndex:(NSInteger*)indexes
{
	for (int i=0; i<ACTIVE_FEED_NUM-1; ++i) {
		activeFeed[i] = indexes[i];
	}
	
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateSegmentTitles:) withObject:(id)nil waitUntilDone:YES];
}

- (NSString*)getTitleInSection:(NSInteger)section useOther:(BOOL)other
{
	NSString* title = nil;
	int index = (other==YES?theOtherIndex:theActiveFeed);
	
	//if (currentFeedIndex >= activeFeed[index]) {
		FeedStorage *feed = contentsArray[activeFeed[index]];
		if (feed) {
			title = getTitle(feed.titleForFeed);
		}
	//}
	
	if (title == nil) {
		title = @"BBC World News";
	}
		
	return title;
}

- (NSInteger)countSection
{
	//NSInteger count = 0;
	
	//return ((count=[contentsArray count])==0?1:count);
	return 1; // will be always one.
}

- (NSInteger)countArticleInSection:(NSInteger)section useOther:(BOOL)other
{
	NSInteger count=0;
	int index = (other==YES?theOtherIndex:theActiveFeed);
	//NSLog(@"%s, %d %d", __func__, index, other);
	//if (currentFeedIndex >= activeFeed[index]) {
	if ([networkService.protectFeed tryLock] == YES) {
		FeedStorage *feed = contentsArray[activeFeed[index]];
		if (feed) {
			count = [feed.rssFeeds count];
			if (count > 60) {
				//NSLog(@"This is bug.");
			}
		}
	}
	[networkService.protectFeed unlock];
	//}
	
	return count;
}

- (NSString*)getArticleTextAtIndex:(NSIndexPath*)indexPath useOther:(BOOL)other
{
	WebLink* article=nil;
	NSString* text=nil;
	int index = (other==YES?theOtherIndex:theActiveFeed);
	
	//int arrayCount = [contentsArray count];
	//if (arrayCount > activeFeed[theActiveFeed]) {
	if ([networkService.protectFeed tryLock] == YES) {
		FeedStorage* feed = contentsArray[activeFeed[index]];
		if (feed) {
			if ([feed count] > indexPath.row) {
				article = [feed.rssFeeds objectAtIndex:indexPath.row];
				if (article) {
					text = article.text;
				}
			}
			else {
				NSLog(@"%s, article may have been shrinked: count: %d, %d", __func__, [feed count], indexPath.row);
			}
			
		}
	}
	[networkService.protectFeed unlock];
	//}
	
	return text;
}

- (NSString*)getArticleImageAtIndex:(NSIndexPath*)indexPath useOther:(BOOL)other available:(BOOL*)isAvailable
{
	WebLink* article=nil;
	NSString* text=nil;
	
	int index = (other==YES?theOtherIndex:theActiveFeed);
	
	//int arrayCount = [contentsArray count];
	//if (arrayCount > activeFeed[theActiveFeed]) {
	if (([networkService.protectFeed tryLock] == YES)) {
		FeedStorage* feed = contentsArray[activeFeed[index]];
		if (feed) {
			if ([feed count] > indexPath.row) {
				article = [feed.rssFeeds objectAtIndex:indexPath.row];
				if (article) {
					text = article.imageLink;
					*isAvailable = article.isAvailable;
				}
			}
			else {
				NSLog(@"%s, article may have been shrinked: count: %d, %d", __func__, [feed count], indexPath.row);
			}
		}
	}
	[networkService.protectFeed unlock];
	//}
	
	return text;
}


- (NSString*)getArticleDescriptionAtIndex:(NSIndexPath*)indexPath useOther:(BOOL)other
{
	WebLink* article=nil;
	NSString* text=nil;
	int index = (other==YES?theOtherIndex:theActiveFeed);
	
	//int arrayCount = [contentsArray count];
	//if (arrayCount > activeFeed[theActiveFeed]) {
	if ([networkService.protectFeed tryLock] == YES) {
		FeedStorage* feed = contentsArray[activeFeed[index]];
		if (feed) {
			if ([feed count] > indexPath.row) {
				article = [feed.rssFeeds objectAtIndex:indexPath.row];
				if (article) {
					text = article.description;
				}
			}
			else {
				NSLog(@"%s, article may have been shrinked: count: %d, %d", __func__, [feed count], indexPath.row);
			}
		}
	}
	[networkService.protectFeed unlock];
	//}
	
	return text;
}


- (FeedStorage*)getFeedStorageRefAtIndex:(NSInteger)index
{
	FeedStorage* storage = nil;
	//int arrayCount = [contentsArray count];
	
	if (articleSize > index) {
		storage = contentsArray[index];
	}
	
	return storage;
}

/*
 * getNextFeedRetrieve:
 *   get next feed to retrieve
 *
 */
- (FeedInformation*)getNextFeedToRetrieve:(int*)index
{
	if (toGetActiveFeed == YES) {
		toGetActiveFeed = NO;
		if (articleMap[activeFeed[theActiveFeed]].avail == NO) {
			NetworkService *service = [NetworkService sharedNetworkServiceInstance];
			[service.doSomething broadcast];
			
			*index = activeFeed[theActiveFeed];
			articleMap[activeFeed[theActiveFeed]].avail = YES;
			return [feedInformationStorage objectAtIndex:activeFeed[theActiveFeed]];
		}
	}
	else {
		
		int i = (theActiveFeed + 1) % (ACTIVE_FEED_NUM-1);
		int j = 0;
		while (j < ACTIVE_FEED_NUM-1) {
			if (articleMap[activeFeed[i]].avail == NO) {
				articleMap[activeFeed[i]].avail = YES;
				*index = activeFeed[i];
				return [feedInformationStorage objectAtIndex:activeFeed[i]];
			}
			i = (i + 1) % (ACTIVE_FEED_NUM-1); j++;
		}
	}
	
	return nil; // don't need to get anything.
}

- (FeedInformation*)getActiveFeed:(int)index
{
	FeedInformation *feed = [feedInformationStorage objectAtIndex:activeFeed[index]];
	return feed;
}

- (FeedStorage*)getActiveFeedStorage:(int)index
{
	return [self getFeedStorageRefAtIndex:activeFeed[index]];
}

- (void)setToActive:(BOOL)active withIndex:(int)index
{
	if (articleMap[index].try_count++ < MAX_TRY_COUNT) {
		articleMap[index].avail = active;
	}
}

- (BOOL)isAvailableOffline:(NSIndexPath*)index
{
	return articleMap[feedBegin[index.section]+index.row].avail;
}

- (void)setArticleSize:(int)size
{
	articleSize = size;
	articleMap = (article_map_t*) malloc(sizeof(article_map_t)*size);
	for (int i=0; i<size; ++i) {
		articleMap[i].avail = NO; // article is not available
		articleMap[i].try_count = 0;
	}
}

- (void)setActiveFeed:(int)index
{
	theActiveFeed = index;
    theActiveFeedOfSegmentControl = theActiveFeed;
}

- (NSString*)getHost 
{
	FeedInformation *feed = [feedInformationStorage objectAtIndex:0];
	return [[NSURL URLWithString:feed.origURL] host];
}

- (NSString*)getActiveArticleTitle
{
	FeedInformation *feed = [feedInformationStorage objectAtIndex:activeFeed[theActiveFeed]];
	return feed.title;
}

/*
- (void)showNextFeed
{
	if ((theActiveFeed + 1) < articleSize) {	
		theActiveFeed++;
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showNextFeed:) withObject:nil waitUntilDone:YES];
	}
}

- (void)showPreviousFeed
{
	if (theActiveFeed > 0) {	
		theActiveFeed--;
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showPreviousFeed:) withObject:nil	waitUntilDone:YES];
	}
}
 */

- (NSArray*)getMostRecentTitles
{
	int i = 0;
	return [[NSArray alloc] initWithObjects:getTitleString(feedInformationStorage, activeFeed[i]),
											getTitleString(feedInformationStorage, activeFeed[i+1]),
											getTitleString(feedInformationStorage, activeFeed[i+2]), nil];
}

- (void)showRecentArticle:(int)index
{
	theActiveFeed = index;
	theActiveFeedOfSegmentControl = theActiveFeed;
	toGetActiveSegment = YES;
	toGetActiveFeed = YES;
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:nil	waitUntilDone:YES];
}

- (NSString*)getTextForSegmentIndex:(int)index
{
	return getTitleString(feedInformationStorage, activeFeed[index]);
}

- (BOOL)showArticle:(NSIndexPath*)index
{
	theActiveFeed = theOtherIndex;
	activeFeed[theActiveFeed] = feedBegin[index.section] + index.row;
	toGetActiveFeed = YES;
	toGetActiveSegment = YES;
	activateOthers = YES;
	
	/*
	for (int i=0; i<ACTIVE_FEED_NUM-1; ++i) {
		if (activeFeed[i] == activeFeed[theOtherIndex]) {
			return YES;
		}
	}
	
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	
	SelectedSegmentIndex *segmentIndex = [[SelectedSegmentIndex alloc] initWithSegmentIndex:index];
	
	[config setIndex:theOtherIndex withNewIndex:activeFeed[theOtherIndex]];
	
	[segmentIndex release];
	*/
	//activeFeed[theActiveFeed] = theOtherIndex;
	/* Don't do this anymore
	for (int i=0; i<ACTIVE_FEED_NUM; ++i) {
		if (activeFeed[i] == index) {
			return NO;
		}
	}
	activeFeed[theActiveFeed] = theOtherIndex;
	*/
	return YES;
	//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:nil	waitUntilDone:YES];
}

- (void)updateOtherIndexToActive
{
	for (int i=0; i<ACTIVE_FEED_NUM-1; ++i) {
		if (activeFeed[i] == activeFeed[theOtherIndex]) {
			return;
		}
	}
	
	
	Configuration *config = [Configuration sharedConfigurationInstance];
	
	SelectedSegmentIndex *segmentIndex = [[SelectedSegmentIndex alloc] initWithSegmentIndex:activeFeed[theOtherIndex]];
	
	[config setIndex:theOtherIndex withNewIndex:activeFeed[theOtherIndex]];
	
	[segmentIndex release];
	
}
/*
 * getNextArticleOfActiveFeed
 *   getting a article link from the current feed.
 *   It will be started from the active feed and get article from the feed.
 *   If that is done for one article, then keep going for the other feed.
 *
 *   theCurrentFeedSegmentIndex: represent a current segment control index
 *   theCurrentArticleIndex: represent an article index in the feed
 *
 *   theActiveFeed: represent the active segment index that shown to user
 *   activeFeed[theActiveFeed]: the article index in the feed storage. it is a xml feed.
 */
- (WebLink*)getNextArticleOfActiveFeed:(NSIndexPath**)indexPath
{
	WebLink *link = nil;
	BOOL hasContent = NO;
	FeedStorage *feed = nil;
	
	if (toGetActiveSegment == YES) {
		theCurrentFeedSegmentIndex = theActiveFeed;
		theCurrentArticleIndex = 0;
		toGetActiveSegment = NO;
	}
	
	int segmentIndex = theCurrentFeedSegmentIndex;
	int articleIndex = theCurrentArticleIndex;
	int activeFeedNum = 0;
	
	if (activateOthers == YES) {
		activeFeedNum = ACTIVE_FEED_NUM;
	}
	else {
		activeFeedNum = ACTIVE_FEED_NUM - 1;
	}
	
	do {
		@synchronized(self) {
			feed = [self getFeedStorageRefAtIndex:activeFeed[theCurrentFeedSegmentIndex]];
			if (feed != nil) {
				link = [feed getWebLinkAtIndex:theCurrentArticleIndex];
				if (link.isAvailable == NO) {
					*indexPath = [NSIndexPath indexPathForRow:theCurrentArticleIndex inSection:activeFeed[theCurrentFeedSegmentIndex]];
					hasContent = YES;
				}
				else {
					link = nil;
				}
			}
			else {
				NSLog(@"%s, feed is null.", __func__);
				theCurrentArticleIndex = -1;
			}
			
			theCurrentArticleIndex++;
			if (theCurrentArticleIndex == ([feed.rssFeeds count])) {
				// fetch everything
				theCurrentArticleIndex = 0;
				theCurrentFeedSegmentIndex = (theCurrentFeedSegmentIndex + 1) % activeFeedNum;
			}
			else if (theCurrentArticleIndex == -1) {
				theCurrentArticleIndex = 0;
				theCurrentFeedSegmentIndex = (theCurrentFeedSegmentIndex + 1) % activeFeedNum;
			}
		}
		
		if (hasContent == YES)
			break;
		
	} while ((segmentIndex != theCurrentFeedSegmentIndex) || (articleIndex != theCurrentArticleIndex));
	
	TRACE("%s, segment: %d, artile: %d, link: %p\n", __func__, theCurrentFeedSegmentIndex, theCurrentArticleIndex, link);
	
	
	return link;
}

- (void)initScrollablePage
{
	currentScrollPage = -1;
}
/* 
 * getNextArticle:
 *    get the next article for imageview. 
 *    will need to return the next one and description,
 *    and also save the last one, so we can continue from it.
 */
- (WebLink*)getNextArticle
{
	WebLink *article = nil;
		
	int startSection = theCurrentSlide.section;
	int startRow = theCurrentSlide.row;
	
	TRACE("%s: section: %d, row: %d\n", __func__, theCurrentSlide.section, theCurrentSlide.row);
	//for (int i=theCurrentSlide.section; i<articleSize; ++i) {
	//i = theCurrentSlide.section;
	theCurrentSlide.row++;
	currentScrollPage++;
	do {
		if (articleMap[theCurrentSlide.section].avail == YES) {
			FeedStorage* feed = [self getFeedStorageRefAtIndex:theCurrentSlide.section];
			
			do {
				
				if (theCurrentSlide.row < [feed count]) {
					article = [feed getWebLinkAtIndex:theCurrentSlide.row];
					if (article.imageLink != nil) {
						return article;
					}
				}
				else {
					theCurrentSlide.row = 0;
					break;
				}
				theCurrentSlide.row++;
				
				if (theCurrentSlide.section == startSection && theCurrentSlide.row == startRow) {
					// looped around, stop here
					return nil;
				}
			} while (theCurrentSlide.row < [feed count]);
			theCurrentSlide.row = 0;
		}
		theCurrentSlide.section = (theCurrentSlide.section + 1) % articleSize;
	} while (theCurrentSlide.section != startSection && theCurrentSlide.row != startRow);
	
	return article;
}

- (WebLink*)getPrevArticle
{
	WebLink *article = nil;
	int startSection = theCurrentSlide.section;
	int startRow = theCurrentSlide.row;
	BOOL resetRowCount = NO;
	
	TRACE("%s : section: %d, row: %d\n", __func__, theCurrentSlide.section, theCurrentSlide.row);

	theCurrentSlide.row--;
	if (currentScrollPage > 0)
		currentScrollPage--;
	do {
		if (articleMap[theCurrentSlide.section].avail == YES) {
			FeedStorage* feed = [self getFeedStorageRefAtIndex:theCurrentSlide.section];
			if (resetRowCount == YES) {
				theCurrentSlide.row = [feed	count] - 1;
				resetRowCount = NO;
			}
			do {
				//NSLog(@"prev 2: section: %d, row: %d", theCurrentSlide.section, theCurrentSlide.row);
				if (theCurrentSlide.row >= 0 && theCurrentSlide.row < [feed count]) {
					article = [feed getWebLinkAtIndex:theCurrentSlide.row];
					if (article.imageLink != nil) {
						return article;
					}
				}
				else {
					theCurrentSlide.row = 0;
					break;
				}
				theCurrentSlide.row--;
				if (theCurrentSlide.section == startSection && theCurrentSlide.row == startRow) {
					// looped around, stop here
					return nil;
				}
			} while (theCurrentSlide.row >= 0);
			theCurrentSlide.row = 0;
		}
		theCurrentSlide.section--;
		resetRowCount = YES;
		if (theCurrentSlide.section <= 0) {
			theCurrentSlide.section = articleSize - 1;
		}
		//NSLog(@"prev 3: section: %d, row: %d", theCurrentSlide.section, theCurrentSlide.row);
	} while (theCurrentSlide.section != startSection || theCurrentSlide.row != startRow);
	
	return article;
}

- (WebLink*)getArticleAtPage:(NSInteger)page 
{
	WebLink *link = nil;
	
	if (currentScrollPage > page) {
		do {
			link = [self getPrevArticle];
		} while (link && currentScrollPage > page);
	}
	else if (currentScrollPage < page) {
		do {
			link = [self getNextArticle];
		} while (link && currentScrollPage < page);
	}
	
	TRACE("%s, page: %d, cur: %d, sec: %d, row: %d\n", __func__, page, currentScrollPage, theCurrentSlide.section, theCurrentSlide.row);
	
	return link;
}

- (void)addImage:(UIImage*)image
{
	[imageStorage addObject:image];
}

- (void)drainImage
{
	for (UIImage *image in imageStorage) {
		[image release];
	}
	[imageStorage removeObjectsInRange:NSMakeRange(0, [imageStorage count])];
}

- (WebLink*)getSelectedLink:(NSIndexPath*)indexPath
{
	WebLink *link = nil;
	
	if (indexPath.section > 0) {
		NSLog(@"%s, out of range in section: %d", __func__, indexPath.section);
		return nil;
	}

	NSLog(@"%s, theActiveFeed: %d, feed: %d, row: %d\n", __func__, theActiveFeed, activeFeed[theActiveFeed], indexPath.row);
	FeedStorage *feed = [self getFeedStorageRefAtIndex:activeFeed[theActiveFeed]];
	
	if ([feed count] > indexPath.row) {
		link = [feed getWebLinkAtIndex:indexPath.row];
	}
	else {
		NSLog(@"%s, out of range in row: %d", __func__, indexPath.row);
		link = nil;
	}
	
	return link;
}

- (NSIndexPath*)fillSelectedLink:(NSIndexPath*)indexPath
{
	
	return [[NSIndexPath indexPathForRow:indexPath.row inSection:activeFeed[theActiveFeed]] copy];
}

- (void)cleanActiveFeedStorage:(int)index
{
	contentsArray[activeFeed[index]] = nil;
}

- (NSInteger)getActiveFeedIndex:(int)index
{
	return activeFeed[index];
}

- (NSString*)getURLFromIndexPath:(NSIndexPath*)indexPath
{
	WebLink *link = nil;
	
	FeedStorage *feed = [self getFeedStorageRefAtIndex:indexPath.section];
	
	if ([feed count] > indexPath.row) {
		link = [feed getWebLinkAtIndex:indexPath.row];
	}
	else {
		NSLog(@"%s, out of range in row: %d", __func__, indexPath.row);
		link = nil;
	}
	return link.url;
}

- (void)setOtherToSemgentWithIndex:(int)index
{
	if (index < ACTIVE_FEED_NUM-1) {
		for (int i=0; i<ACTIVE_FEED_NUM-1; ++i) {
			if (activeFeed[i] == activeFeed[theOtherIndex]) {
				return;
			}
		}

		Configuration *config = [Configuration sharedConfigurationInstance];
		
		SelectedSegmentIndex *segmentIndex = [[SelectedSegmentIndex alloc] initWithSegmentIndex:index];
		activeFeed[index] = activeFeed[theOtherIndex];
		[config setIndex:index withNewIndex:activeFeed[theOtherIndex] fromSegment:theOtherIndex];
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(reloadArticleWithIndex:) withObject:(id)segmentIndex waitUntilDone:YES];

		[segmentIndex release];
	}
	else {
		NSLog(@"%s, out of range: %d", __func__, index);
	}
}

- (article_nav_mode_t)articleNaviationMode
{
	return theNavMode;
}

- (void)switchToArticleNavigation
{
	theNavMode = ARTICLE_MAIN_NAV_MODE;
	theActiveFeed = theActiveFeedOfSegmentControl;
}

- (void)switchToOthersNavigation
{
	theNavMode = ARTICLE_OTHER_NAV_MODE;
	theActiveFeed = theOtherIndex;
}

- (NSInteger)getNumberOfImages
{
	return numberOfImages;
}

- (NSInteger)getFeedIndexForSegment:(NSInteger)segment
{
	return activeFeed[segment];
}

- (void)setToActiveFeed:(NSInteger*)indexes
{
	Configuration *config = [Configuration sharedConfigurationInstance];
	
	for (int i=0; i<NUM_FEED; ++i) {
		activeFeed[i] = indexes[i];
		[config setIndex:i withNewIndex:indexes[i]];
	}
	
	[config saveSettings];
	[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateSegmentTitles:) withObject:(id)nil waitUntilDone:YES];	
	NetworkService *service = [NetworkService sharedNetworkServiceInstance];
	[service.doSomething broadcast];
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

// TODO: clean article storage.
+ (void)releaseArticles
{
	int i=0;
	ArticleStorage* sharedStorage = [ArticleStorage sharedArticleStorageInstance];
	for (i=0; i<sharedStorage.articleSize; ++i) {
		FeedStorage* feed = sharedStorage.contentsArray[i];
		// Since init and add to the array will increate count to 2.
		// No longer added to the array.
		[feed release];
	}
	
	[sharedStorage.FeedsArray release];
}

@end
