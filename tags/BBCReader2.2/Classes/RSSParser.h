//
//  RSSParser.h
//  NYTReader
//
//  Created by Jae Han on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSParserState.h"

@class WebLink;

@interface RSSParser : NSObject {

	@private
	RSSParserState	*parserState;
	WebLink			*currentArticleHolder;
	WebLink			*titleHolder;
	NSInteger		currentFeedIndex;
	NSInteger		currentElementLevel;
	NSInteger		titleElementLevel;
}

- (void)setCurrentFeedIndex:(NSInteger)index;
- (void)setParserAtElementName:(NSString*)name;
- (void)addCharactersInText:(NSString*)string;
- (void)endElement:(NSString*)name;
- (void)prepareArticleHolder;
- (void)setArticleTitle:(NSString*)title;
- (void)setArticleURL:(NSString*)url;
- (void)prepareTitleHolder; 
- (void)setArticleDescription:(NSString*)description;
- (void)setBuildDate:(NSString*)date;
- (void)setArticleTTL:(NSInteger)ttl;

@end
