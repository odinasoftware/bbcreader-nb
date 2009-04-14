//
//  HTTPConnection.h
//  NYTReader
//
//  Created by Jae Han on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HTTPConnection : NSObject {
	@private
	NSIndexPath		*indexForFeed; // index for RSS feed
	NSData	*receivedData; // received data per connection.
	NSString		*localFile;
}

@property (nonatomic, assign) NSIndexPath *indexForFeed;
@property (nonatomic, assign) NSData *receivedData;
@property (nonatomic, assign) NSString *localFile;

//- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;

@end
