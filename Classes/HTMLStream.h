//
//  HTMLStream.h
//  NYTReader
//
//  Created by Jae Han on 7/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HTMLStream : NSObject {
	NSData		*streamData;
	const void	*streamBytes;
	NSUInteger	currentReadPointer;
	NSUInteger	length;
}

- (void)setupStream:(NSData*)data;
- (int)readFromStream;

@end
