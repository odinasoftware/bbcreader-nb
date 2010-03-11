

#import "FeedInformation.h"

@implementation FeedInformation

@synthesize title;
@synthesize origURL;
@synthesize localFileName;


- (id)initWithFeedInformation:(NSString*)key origURL:(NSString*)url
{
	if (self = [super init]) {
		// We may append temporary directory here 
		//localFileName = NSTemporaryDirectory();
		//localFileName = [localFileName stringByAppendingString:localName];
		// or do this later in HTTP service.
		title = key;
		
		origURL = url;
		//NSLog(@"%@: %@", localFileName, localName);
	}
	return self;
}

- (void)dealloc
{
	[title release];
	[origURL release];
	[localFileName release];
	
	[super dealloc];
}

@end
