
#import <UIKit/UIKit.h>

/* FeedInformation
 *	 represent a feed tuple <local name, original URL>
 */
@interface FeedInformation : NSObject {
	NSString	*title;
	NSString	*localFileName;
	NSString	*origURL;
}

- (id)initWithFeedInformation:(NSString*)key origURL:(NSString*)url;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *origURL;
@property (nonatomic, retain) NSString *localFileName;

@end