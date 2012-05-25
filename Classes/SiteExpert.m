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

/*
 ---- one way -----
 <div class="story-inner">
 <h1>Michael Gove calls for faith pupil limit in Twickenham school</h1>
 <div class="byline">
 <p>
 <span class="name">
 By Angela  Harrison                         </span>
 <span class="bbc-role">
 Education correspondent, BBC News                         </span>
 </p>
 <p class="date" data-seconds="1333132546"><strong>30 March 2012</strong> Last updated at 18:35</p>
 </div>
 
 
 <figure><img src="http://localhost:9000/cache/newsrss.bbc.co.uk/default/3070882802.jpg" alt="classroom scene" class="lead"><figcaption><span class="cap">Most new schools will be free schools and academies</span></figcaption></figure><p class="introduction">Education Secretary Michael Gove has suggested a proposed new Catholic school should limit Catholic pupils to 50% of its intake.</p><p>Business Secretary Vince Cable wrote to Mr Gove about the proposed school, which is in his Twickenham constituency.</p><p>Mr Gove said the proposal for a cap was "very sensible".</p><p>But a Catholic Education Service official said turning Catholics away and admitting others just because they were not Catholic would be "odd".</p><p>A few years ago, the Roman Catholic Church fought attempts by Labour to open up new Church schools in England to the wider population.</p><p>Letters between the two ministers have been leaked and copies seen by the BBC.</p><p>New laws mean that new free schools and academies, if they are faith-based, have to limit their "faith intake" to 50% of the total, if they are over-subscribed.</p><p>But such legislation does not apply to the school being proposed by the Diocese of Westminster for a site in Clifden Road in Twickenham, south-west London.</p><p>That plan is for a voluntary-aided school.</p><p>Generally, the Church says its schools in London are oversubscribed by Catholics, while others elsewhere have a more mixed intake.</p><p class="crosshead">'Very sensible'</p><p>In a reply to Mr Cable, Mr Gove wrote: "The school will be able to admit pupils on the grounds of faith, but the 50% non-faith provision for the schools admissions will not apply.</p><p>"The suggestion that the school takes on a similar position voluntarily seems very sensible to me, and I would welcome such a move."</p><p>The deputy director of the Catholic Education Service, Greg Pope, said Catholic parents in the area had been asking for the school.</p><p>"We would not seek to open a new voluntary-aided school unless there was demand to fill it," he said.</p><p>"Given that there is [demand], that means you would be in the odd position where you build a Catholic school and turn Catholics away and offer others places simply on the grounds that they are not Catholic.</p><p>"That would be extraordinary."</p><p>Richmond Council has consulted on the proposals for the school, which is earmarked for the former site of an adult education college.</p><p>The plan, if approved, would mean the 1,000-pupil mixed school would open in September 2013.</p><p>There are also plans for a Catholic primary school at the same site. There are no Catholic secondaries in the borough and the council says every year 200 children start at Catholic secondary schools in other boroughs.</p><p>The council will vote on the plans in late May.</p><p>It says alternative proposals have been put forward for four free schools for the area and decisions on those are not expected until the summer.</p><p>The Richmond Inclusive Schools Campaign has collected more than 3,000 signatures on a petition asking the council to ensure that every state-funded school opening in the borough from now on is open to all.</p><p class="crosshead">'Discriminate'</p><p>The group is supported by the Accord Coalition, which aims to promote "inclusive schools".</p><p>Chairman of the group Rabbi Jonathan Romain said he was encouraged by Mr Gove's comments.</p><p>"The freedom that faith schools have to discriminate in the selection of pupils on religious grounds has long passed its sell-by date," he said.</p><p>Mr Pope, from the Catholic Education Service, said he was not concerned about Mr Gove's comments, because the Church had received assurances from the Department for Education and the law was clear.</p><p>The 50% limit could not be applied to voluntary-aided faith schools which became academies, he added.</p><p>Dozens of Catholic schools in England are currently switching to academy status, together with other community schools. There are now 68 Catholic academies and Mr Pope estimates there will be "hundreds" by the end of the year.</p>
 
 </div>
 
 ---- other way ------
 <figure>
 <img src="http://localhost:9000/cache/newsrss.bbc.co.uk/default/3070882802.jpg" alt="classroom scene" class="lead"><figcaption><span class="cap">Most new schools will be free schools and academies</span></figcaption></figure>
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
	
    //TRACE("%s, key: %s, v: %s\n", __func__, [key UTF8String], [value UTF8String]);
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
			 ([(NSString*)value compare:@"story-inner"] == 0)) {
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

