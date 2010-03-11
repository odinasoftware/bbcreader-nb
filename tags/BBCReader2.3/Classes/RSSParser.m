//
//  RSSParser.m
//  NYTReader
//
//  Created by Jae Han on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "RSSParser.h"
#import "WebLink.h"
#import "ArticleStorage.h"
#import "BBCReaderAppDelegate.h"
#import "AppDelegateMethods.h"


NSString* RSS_ITEM_STRING = @"item";
NSString* RSS_CHANNEL_STRING = @"channel";

@implementation RSSParser

+(void)initialize {
}

-(id) init {
	if ((self = [super init])) {
		parserState = nil;
		currentArticleHolder = nil;
		titleHolder = nil;
		currentFeedIndex = -1;
		currentElementLevel = 0;
		titleElementLevel = -1;
	}
	return self;
}

- (void)setCurrentFeedIndex:(NSInteger)index 
{
	currentFeedIndex = index;
}

-(void) setParserAtElementName:(NSString*) name {
	//RSSParserState *inst=nil;
	
	// Going one level down
	currentElementLevel++; 
	
	if ([name isEqualToString:RSS_CHANNEL_STRING]) {
		TRACE("channel to parse.\n");
		parserState = [RSSChannelState getInstance:self];
	}
	/* Use cache response instead
	else if ([name isEqualToString:@"lastBuildDate"]) {
		parserState = [RSSParserState getInstance:self];
	}
	else if ([name isEqualToString:@"ttl"]) {
	}
	 */
	else if ([name isEqualToString:RSS_ITEM_STRING]) {
		//NSLog(@"New item starts");
		parserState = [RSSParserState getInstance:self];
	}
	else if ((currentArticleHolder || titleHolder) && [name isEqualToString:@"title"]) {
		//NSLog(@"setting parser to title");
		parserState = [RSSTitleState getInstance:self];
	}
	else if ((currentArticleHolder || titleHolder) && [name isEqualToString:@"link"]) {
		//NSLog(@"settng parser to link");
		parserState = [RSSLinkState getInstance:self];
	}
	else if ((currentArticleHolder || titleHolder) && [name isEqualToString:@"description"]) {
		//NSLog(@"settng parser to link");
		parserState = [RSSDescriptionState getInstance:self];
	}
	else {
		parserState = nil;
	}
	
	//if (parserState == nil) {
	//	NSLog(@"parseWithelementName, can't find a parser for this element: %@", name);
	//}
	//else {
		//[parserState prepareNewPage];
	//	[parserState startElement];
	//}
	
	[parserState startElement];
	
}

-(void) addCharactersInText:(NSString*)string {
	if (parserState == nil) {
		//NSLog(@"RSSParser, can't add string.");
	}
	else {
		//NSLog(@"add string to text: %@", string);
		[parserState addCharactersInText:string];
	}
}

-(void) endElement:(NSString*)name {
	// One level up
	currentElementLevel--;
	if ([name isEqualToString:RSS_ITEM_STRING]) {
		if (titleHolder != nil) {
			[ArticleStorage addChannel:titleHolder atIndex:currentFeedIndex];
			titleHolder = nil;
		}
		if (currentArticleHolder != nil) {
			//[contentsArray addObject:currentArticleHolder];
			[ArticleStorage addArticle:currentArticleHolder atIndex:currentFeedIndex];
			currentArticleHolder = nil;
			// TODO: Updating TableView whenever data available isnt' very good idea.
			//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:currentArticleHolder	waitUntilDone:YES];
		}
	}
	else {
		[parserState endElement:name];
	}
	
}

-(void) prepareArticleHolder {
	if (currentArticleHolder) {
		TRACE("prepareArticleHolder: detect pending article.\n");
	}
	WebLink* holder = [[WebLink alloc] init];
	
	currentArticleHolder = holder;
}

- (void)prepareTitleHolder 
{
	if (titleHolder) {
		TRACE("prepareTitleHolder: detect pending title holder.\n");
	}
	WebLink* holder = [[WebLink alloc] init];
	
	titleHolder = holder;
	titleElementLevel = currentElementLevel;
}

-(void) setArticleTitle:(NSString*)title {
	if (currentArticleHolder) {
		currentArticleHolder.text = title;
	}
	else if (titleHolder && (currentElementLevel == titleElementLevel)) {
		// Otherwise, getting channel information.
		titleHolder.text = title;
		titleElementLevel = -1;
	}
}

-(void) setArticleURL:(NSString*)url {
	if (currentArticleHolder) {
		currentArticleHolder.url = url;
	}
	else if (titleHolder) {
		// otherwise, getting channel information.
		titleHolder.url = url;
	}
}

- (void)setArticleDescription:(NSString*)description 
{
	if (currentArticleHolder) {
		currentArticleHolder.description = description; //[description stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	else if (titleHolder) {
		// otherwise, getting channel information.
		titleHolder.description = description; //[description stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
}

- (void)setBuildDate:(NSString*)date
{
	[ArticleStorage setChannelBuildDate:date atIndex:currentFeedIndex];	
}

- (void)setArticleTTL:(NSInteger)ttl
{
	[ArticleStorage setChannelTTL:ttl atIndex:currentFeedIndex];
}

@end
