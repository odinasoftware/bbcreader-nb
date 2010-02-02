//
//  ArticleStorage.h
//  NYTReader
//
//  Created by Jae Han on 7/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct section_t {
	int section;
	int row;
} section_t;

typedef struct article_map_t {
	BOOL avail;
	int  try_count;
} article_map_t;
	
typedef enum {ARTICLE_MAIN_NAV_MODE, ARTICLE_OTHER_NAV_MODE} article_nav_mode_t;

// Three segment control and one for other navigation.
#define ACTIVE_FEED_NUM	4
#define NUM_FEED 3
@class WebLink;
@class FeedStorage;
@class FeedInformation;
@class NetworkService;

/* ArticleStorage
 *	Represent whole xml feed for a site. 
 *	For example, www.newyorker.com will have one ArticleStorage.
 */
 
@interface ArticleStorage : NSObject {
	id				*contentsArray;			// Store all feeds
	FeedStorage		*currentFeedStorage;
	// theActiveFeed: the segment index that represent the current active index.
	// It can be one of segment index or other that is 3. 
	NSInteger		theActiveFeed;
	// theActiveFeedOfSegmentControl: the index of current article nagivation index
	NSInteger		theActiveFeedOfSegmentControl;
	NSMutableArray *feedInformationStorage;  // Store xml feeds
	//NSMutableArray *feedInformationStorage1;  // Store xml feeds
	//NSMutableArray *feedInformationStorage2;  // Store xml feeds
	int				articleSize;
	NSInteger		feedBegin[NUM_FEED];
	
	@private
	article_map_t	*articleMap;
	BOOL			toGetActiveFeed;
	BOOL			toGetActiveSegment;
	BOOL			activateOthers;
	int				activeFeed[ACTIVE_FEED_NUM];
	int				theCurrentFeedSegmentIndex;
	int				theCurrentArticleIndex;
	int				theOtherIndex;
	NSArray			*FeedsArray;
	NSArray			*sportFeedsArray;
	NSArray			*mobileFeedsArray;
	//NSArray			*internationalFeedsArray;
	NSMutableArray	*imageStorage;
	section_t		theCurrentSlide;
	article_nav_mode_t theNavMode;
	NSInteger		numberOfImages;
	NSInteger		numberOfArticles;
	NSInteger		numberOfChannel;
	NSInteger		currentScrollPage;
	NetworkService	*networkService;
}

@property (nonatomic, assign) id* contentsArray;
@property (nonatomic, retain) FeedStorage *currentFeedStorage;
@property (nonatomic, retain) NSMutableArray* feedInformationStorage;
@property (nonatomic, assign) NSInteger theActiveFeed;
@property (nonatomic, assign) int articleSize;
@property (nonatomic, assign) NSArray* FeedsArray;
@property (assign) NSInteger numberOfImages;
@property (assign) NSInteger numberOfArticles;
@property (assign) NSInteger numberOfChannel;

+ (ArticleStorage*)sharedArticleStorageInstance;
+ (void)addArticle:(WebLink*)article atIndex:(NSInteger)index;
+ (void)addChannel:(WebLink*)channel atIndex:(NSInteger)index;
+ (void)setImageLink:(NSString*)imageFile atIndexPath:(NSIndexPath*)indexPath;
+ (void)releaseArticles;
+ (void)setChannelBuildDate:(NSString*)date atIndex:(NSInteger)index;
+ (void)setChannelTTL:(NSInteger)ttl atIndex:(NSInteger)index;

- (NSString*)getTitleInSection:(NSInteger)section useOther:(BOOL)other;
- (NSInteger)countSection;
- (NSInteger)countArticleInSection:(NSInteger)index useOther:(BOOL)other;
- (NSString*)getArticleTextAtIndex:(NSIndexPath*)indexPath useOther:(BOOL)other;
- (FeedStorage*)getFeedStorageRefAtIndex:(NSInteger)index;
- (NSString*)getArticleDescriptionAtIndex:(NSIndexPath*)indexPath useOther:(BOOL)other;
- (NSString*)getArticleImageAtIndex:(NSIndexPath*)indexPath useOther:(BOOL)other available:(BOOL*)isAvailable;
- (FeedInformation*)getNextFeedToRetrieve:(int*)index;
- (void)setArticleSize:(int)size;
- (NSString*)getHost;
- (void)setActiveFeed:(int)index;
- (NSString*)getActiveArticleTitle;
//- (void)showNextFeed;
//- (void)showPreviousFeed;
- (NSArray*)getMostRecentTitles;
- (void)showRecentArticle:(int)index;
- (WebLink*)getNextArticleOfActiveFeed:(NSIndexPath**)indexPath;
- (BOOL)showArticle:(NSIndexPath*)index;
- (void)addImage:(UIImage*)image;
- (void)drainImage;
- (WebLink*)getNextArticle;
- (WebLink*)getPrevArticle;
- (WebLink*)getSelectedLink:(NSIndexPath*)indexPath;
- (NSString*)getTextForSegmentIndex:(int)index;
- (void)switchToArticleNavigation;
- (void)switchToOthersNavigation;
- (article_nav_mode_t)articleNaviationMode;
- (void)setOtherToSemgentWithIndex:(int)index;
- (NSInteger)getNumberOfImages;
- (void)initScrollablePage;
- (WebLink*)getArticleAtPage:(NSInteger)page;
- (void)initSegmentIndex:(NSInteger*)indexes;
- (NSIndexPath*)fillSelectedLink:(NSIndexPath*)indexPath;
- (NSString*)getURLFromIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isAvailableOffline:(NSIndexPath*)index;
- (void)updateOtherIndexToActive;
- (void)setToActive:(BOOL)active withIndex:(int)index;
- (FeedInformation*)getActiveFeed:(int)index;
- (FeedStorage*)getActiveFeedStorage:(int)index;
- (void)cleanActiveFeedStorage:(int)index;
- (NSInteger)getActiveFeedIndex:(int)index;
- (NSInteger) numberOfFeedSections;
- (NSInteger)numberOfFeeds:(NSInteger)component;
- (NSString*)getSectionTitle:(NSInteger)row withComponent:(NSInteger)component  bySelection:(NSInteger)selection;
- (NSInteger)getFeedIndexForSegment:(NSInteger)segment;
- (NSInteger)getArticleIndexWith:(NSInteger)row andSelection:(NSInteger)selection;
- (void)setToActiveFeed:(NSInteger*)indexed;
- (NSInteger)countInSection:(NSInteger)section;
- (FeedInformation*)feedByIndexPath:(NSIndexPath*)index;

@end
