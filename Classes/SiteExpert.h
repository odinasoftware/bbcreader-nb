//
//  SiteExpert.h
//  NYTReader
//
//  Created by Jae Han on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTMLParser;

typedef enum {SITE_EXPERT_NONE, SITE_EXPERT_BEGIN, SITE_EXPERT_DONE, SITE_EXPERT_END} SiteExpertStatus;

@interface SiteExpert : NSObject {
	HTMLParser *theParser;
	SiteExpertStatus status;
	NSIndexPath *theIndexPath;
}

- (id)initWithParser:(HTMLParser*)parser;
- (BOOL)querySiteKnowledgeWithKey:(id)key;
- (BOOL)querySiteKnowledgeWithKey:(id)key withValue:(id)value;
- (BOOL)setSiteKnowledge:(id)value withExtra:(id)extra forKey:(id)key;
- (void)startSiteExpert:(NSIndexPath*)indexPath;
- (void)stopSiteExpert;
- (void)resetKnowledge;

@end

@interface NewYorkerSiteExpert : SiteExpert {
	BOOL lookAtDivAnchorPattern;
	int foundPossiblePicture;
}


@end


@interface BBCSiteExpert : SiteExpert {
	@private
	BOOL		foundStoryBody;
	NSInteger	previousIndex;
    BOOL        thumbAdded;
}


@end

