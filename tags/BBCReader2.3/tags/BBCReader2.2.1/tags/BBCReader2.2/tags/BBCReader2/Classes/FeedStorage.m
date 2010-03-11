
#import "FeedStorage.h"
#import "WebLink.h"
#import "NetworkService.h"

@implementation FeedStorage

@synthesize rssFeeds;
@synthesize titleForFeed;
@synthesize buildDate;
@synthesize ttl;

- (id)init
{
	if ((self = [super init])) {
		rssFeeds = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSInteger)count 
{
	return [rssFeeds count];
}

- (WebLink*)getWebLinkAtIndex:(NSInteger)index
{
	WebLink *l = nil;
	
	
	if ([rssFeeds count] > index) {
		l = [rssFeeds objectAtIndex:index];
	}
	else {
		NSLog(@"%s, index error. %d, %d", __func__, [rssFeeds count], index);
	}
	
	
	return l;
}

- (void)dealloc
{
	/*
	int i=0;
	
	for (i=0; i<[rssFeeds count]; ++i) {
		id instance = [rssFeeds objectAtIndex:i];
		[instance release];
	}
	 */
	[rssFeeds release];
	[titleForFeed release];
	[buildDate release];
	[super dealloc];
}

@end
