//
//  HTMLStream.m
//  NYTReader
//
//  Created by Jae Han on 7/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HTMLStream.h"


@implementation HTMLStream

- (id)init
{
	if ((self = [super init])) {
		streamData = nil;
		streamBytes = nil;
		currentReadPointer = 0;
		length = 0;
	}
	return self;
}

- (void)setupStream:(NSData*)data
{
	streamData = data;
	streamBytes = [data bytes];
	length = [data length];
	currentReadPointer = 0;
}

- (int)readFromStream
{
	int data = -1;
	if (currentReadPointer < length)
		data = *(unsigned char*)((unsigned int)streamBytes + currentReadPointer++);
	
	return data;
}

- (void)dealloc {
	[super dealloc];
}


@end
