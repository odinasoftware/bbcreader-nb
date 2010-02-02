
#import <UIKit/UIKit.h>

@class WebLink;
@class NetworkService;

/* FeedStorae
 *   represent a xml feed.  
 */
@interface FeedStorage : NSObject {
	NSString		*titleForFeed;
	NSMutableArray	*rssFeeds;
	NSDate			*buildDate;
	NSInteger		ttl;
}

@property (nonatomic, retain) NSMutableArray *rssFeeds;
@property (nonatomic, retain) NSString* titleForFeed;
@property (nonatomic, retain) NSDate* buildDate;
@property (nonatomic, assign) NSInteger ttl;

- (NSInteger)count;
- (WebLink*)getWebLinkAtIndex:(NSInteger)index;

@end