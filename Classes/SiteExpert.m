//
//  SiteExpert.m
//  NYTReader
//
//  Created by Jae Han on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SiteExpert.h"
#import	"HTMLParser.h"
#import "ThumbNailHolder.h"

static const NSString *local_host_prefix = @"http://localhost:9000";

@implementation SiteExpert

- (id)initWithParser:(HTMLParser*)parser 
{
	if ((self = [super init])) {
		theParser = parser;
	}
	return self;
}

- (BOOL)querySiteKnowledgeWithKey:(id)key
{
	return NO;
}

- (BOOL)setSiteKnowledge:(id)value withExtra:(id)extra forKey:(id)key
{
	return NO;
}

- (void)startSiteExpert:(NSIndexPath*)indexPath
{
	status = SITE_EXPERT_BEGIN;
	theIndexPath = indexPath;
}

- (void)stopSiteExpert
{
	status = SITE_EXPERT_END;
	theIndexPath = nil;
}

- (void)resetKnowledge
{
}

- (BOOL)querySiteKnowledgeWithKey:(id)key withValue:(id)value
{
	return NO;
}

@end


@implementation NewYorkerSiteExpert

// Looking for this pattern
// <div class="img-shadow"><img src="/images/2008/08/25/p233/080825_r17641_p233.jpg" alt="Giordano Bruno fled the Inquisition to write and to speak across Northern Europe."  /></div>

- (id)initWithParser:(HTMLParser*)parser 
{
	if ((self = [super init])) {
		theParser = parser;
		lookAtDivAnchorPattern = NO;
		status = SITE_EXPERT_NONE;
		foundPossiblePicture = 0;
	}
	return self;
}

- (BOOL)setSiteKnowledge:(id)value withExtra:(id)extra forKey:(id)key
{
	BOOL ret = NO;
	
	if (lookAtDivAnchorPattern == NO) {
		if (([(NSString*)key compare:@"class"] == 0) && 
			([(NSString*)value compare:@"img-shadow"] == 0)) {
			lookAtDivAnchorPattern = YES;
		}
	}
	else if ((theParser.divOpen == YES) && (theParser.anchorOpen == NO)) {
		// When there is a div and no anchor, but image is presented, 
		// it will be the representitive picture
		if ([(NSString*)key compare:@"src"] == 0) {
			TRACE("%s: %s\n", __func__, [(NSString*)value UTF8String]);
			foundPossiblePicture++;
		}
		// Only the first one will be the one.
		if (foundPossiblePicture == 1) {
			// TODO: found the proper object, store to the main picture storage
			ret = YES;
			if (theIndexPath == nil) {
				NSLog(@"%s, index path is null.", __func__);
			}
			[ThumbNailHolder addThumbnail:(NSString*)value withLocalName:(NSString*)extra atIndexPath:theIndexPath];
		}
		
		lookAtDivAnchorPattern = NO;
	}
	
	return ret;
}

- (void)resetKnowledge
{
	foundPossiblePicture = 0;
}


@end

@implementation BBCSiteExpert

// Look for this pattern
//<meta name="THUMBNAIL_URL" content="http://newsimg.bbc.co.uk/media/images/44942000/jpg/_44942187_aldilidl203i.jpg" />

/*
<tr>
<td class="storybody">

<!-- S BO -->
<!-- S IIMA -->

<table border="0" cellspacing="0" align="right" width="226" cellpadding="0">

<tr><td>
<div>
<img src="http://newsimg.bbc.co.uk/media/images/45449000/jpg/_45449212_afptsvangirai226b.jpg" width="226" height="170" alt="Morgan Tsvangirai" border="0" vspace="0" hspace="0">

<div class="cap">Morgan Tsvangirai is expected to be sworn in on 11 February</div>

</div>

</td></tr>
</table>
 */

/*
 <tr>
 <td class="storybody">
 <!-- S BO -->
 <!-- S IIMA -->
 
 
 
 <div>
 <img src="http://newsimg.bbc.co.uk/media/images/45455000/jpg/_45455505_jadenmeck_gwentpolice_466x2.jpg" width="466" height="282" alt="Jaden Mack" border="0" vspace="0" hspace="0">
 <div class="cap">Jaden Mack, aged three-and-a-half-months, was declared dead in hospital </div>
 </div>
*/

/*
 <tr>
 <td class="storybody">
 <!-- S BO -->
 
 
 
 
 <!-- S IBOX -->
 <table cellspacing="0" align="right" width="231" border="0" cellpadding="0">
 <tr>
 <td width="5"><img src="http://newsimg.bbc.co.uk/shared/img/o.gif" width="5" height="1" alt="" border="0" vspace="0" hspace="0"></td>
 <td class="sibtbg">
 
 
 
 <div class="o">
 <img src="http://newsimg.bbc.co.uk/media/images/45456000/jpg/_45456097_awt282i.jpg" width="226" height="282" alt="Antony Worrall Thompson" border="0" vspace="0" hspace="0">
 </div>
 
 
 
 <div>
*/ 
/* For mobile page
<div class="downlink"><a href="#navigation">Menu</a></div> <h1>Iraq violence 'may have prompted UK rethink'</h1> <div class="date">16 December 09 17:49 GMT</div> 
 <img src="http://newsimg.bbc.co.uk/media/images/46931000/jpg/_46931088_000748208-1.jpg" width="66" height="49" alt=""> 
 */
/*
<div class="downlink"><a href="#navigation">Menu</a></div> <h1>Cheques to be phased out in 2018</h1> 
 <div class="date">16 December 09 16:24 GMT</div> 
 <img src="http://newsimg.bbc.co.uk/media/images/45971000/jpg/_45971561_002320645-1.jpg" width="66" height="49" alt=""> 
 */

- (id)initWithParser:(HTMLParser*)parser 
{
	if ((self = [super init])) {
		theParser = parser;
		foundStoryBody = NO;
		previousIndex = -1;
        thumbAdded = NO;
	}
	return self;
}

- (BOOL)setSiteKnowledge:(id)value withExtra:(id)extra forKey:(id)key
{
	BOOL ret = NO;
	BOOL addToThumbnail = NO;
	
	if (theIndexPath == nil)
		return ret;
	
	if (([(NSString*)key compare:@"name"] == 0) && 
		([(NSString*)value compare:@"THUMBNAIL_URL"] == 0)) {
		// Just pass, we may see "content" next time.
		ret = YES;
	}
	else if ([(NSString*)key compare:@"content"] == 0) {
		// We really see "content", which means that it is the thumbnail.
		addToThumbnail = YES;
	}
	else if (([(NSString*)key compare:@"class"] == 0) && 
			 ([(NSString*)value compare:@"storybody"] == 0)) {
		// found storybody, great change to have embedded image
		foundStoryBody = YES;
	}
	else if (([(NSString*)key compare:@"class"] == 0) && 
			 ([(NSString*)value compare:@"downlink"] == 0)) {
		// found image block for mobil page.
		foundStoryBody = YES;
	}
	else if (foundStoryBody == YES && [(NSString*)key compare:@"src"] == 0) {
		if ([[(NSString*)value pathExtension] compare:@"jpg"] == NSOrderedSame) {
			// We found an image. When this is called, everything is done. 
			// so we should reset the knowledge. 
			addToThumbnail = YES;
			foundStoryBody = NO;
		}
	}
	else if (foundStoryBody == YES && [(NSString*)key compare:@"/table"] == 0) {
		foundStoryBody = NO;
	}
	
	if (thumbAdded == NO && addToThumbnail == YES && value != nil) {
		ret = YES;
		if (theIndexPath == nil) {
			NSLog(@"%s, index path is null.", __func__);
		}
		
		// TODO: takeout http://localhost:9000
		NSRange range = [(NSString*)extra rangeOfString:(NSString*)local_host_prefix];
		
		if (previousIndex == -1) {
			previousIndex = [ThumbNailHolder addThumbnail:(NSString*)value withLocalName:[(NSString*)extra substringFromIndex:range.length] atIndexPath:theIndexPath];
		}
		else {
			[ThumbNailHolder addThumbnail:(NSString*)value withLocalName:[(NSString*)extra substringFromIndex:range.length] atIndexPath:theIndexPath withPrevIndex:previousIndex];
		}
		TRACE("Found thumbnail: %s, at: (%d, %d) on %d\n", [(NSString*) value UTF8String], theIndexPath.section, theIndexPath.row, previousIndex);
        addToThumbnail = NO;
        thumbAdded = YES;
	}
	
	return ret;
}

- (BOOL)querySiteKnowledgeWithKey:(id)key
{
	BOOL ret = NO;
	
	if ([(NSString*)key compare:@"content"] == 0) {
		ret = YES;
	}
	
	return ret;
}

- (BOOL)querySiteKnowledgeWithKey:(id)key withValue:(id)value
{
	BOOL ret = NO;
	
	if (foundStoryBody == YES && [(NSString*)key compare:@"src"] == 0) {
		if ([[(NSString*)value pathExtension] compare:@"jpg"] == NSOrderedSame) {
			ret = YES;
		}
	}
	
	return ret;
}

- (void)resetKnowledge
{
    thumbAdded = NO;
	foundStoryBody = NO;
	previousIndex = -1;
}

@end

