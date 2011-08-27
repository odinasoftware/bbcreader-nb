//
//  XMLReader.h
//  NYTReader
//
//  Created by Jae Han on 6/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSSParserState;
@class RSSParser;

@interface XMLReader : NSObject <NSXMLParserDelegate> {
	RSSParser *rssParser;
}

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error withIndex:(NSInteger)index;
- (void)parseXMLData:(NSData*) data parseError:(NSError**) error withIndex:(NSIndexPath*)indexPath shouldNotify:(BOOL)notify;

@end
