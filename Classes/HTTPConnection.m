//
//  HTTPConnection.m
//  NYTReader
//
//  Created by Jae Han on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HTTPConnection.h"


@implementation HTTPConnection

@synthesize indexForFeed;
@synthesize receivedData;
@synthesize localFile;

- (id)init 
{
	if ((self = [super init])) {
		indexForFeed = nil;
		receivedData = nil;
		localFile = nil;
	}
	return self;
}
//- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
//{
	
//}

- (void)dealloc
{
	//[indexForFeed release];
	//[receivedData release];
	//[localFile release];
	
	[super dealloc];
}

@end
