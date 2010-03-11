//
//  RSSParserState.m
//  NYTReader
//
//  Created by Jae Han on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"

#import "RSSParserState.h"
#import "WebLink.h"
#import "RSSParser.h"

static RSSParserState *rssParserInstance=nil;
static RSSTitleState *rssTitleInstance=nil;
static RSSLinkState *rssLinkInstance=nil;
static RSSGUIDState *rssGUIDInstance=nil;
static RSSChannelState* rssChannelInstance=nil;
static RSSDescriptionState* rssDescriptionInstance=nil;
static RSSBuildDateState* rssBuildDateInstance = nil;
static RSSTTLState* rssTTLInstance = nil;


#define DEFAULT_MSG_SIZE 128

@implementation RSSParserState

//@synthesize text;
//@synthesize currentLink;

-(id) initWithDelegate:(RSSParser*)delegate {
	if (self = [super init]) {
		parserDelegate = delegate;
		//currentLink = nil;
		elementEnded = NO;
	}
	return self;
}


+(RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssParserInstance == nil) {
		rssParserInstance = [[RSSParserState alloc] initWithDelegate:delegate];
	}
	return rssParserInstance;
}

-(void) addCharactersInText:(NSString*)string {
}

-(BOOL) startElement {
	BOOL ret = YES;
	
	//[currentLink release];
	//currentLink = [[WebLink alloc] init];
	[parserDelegate prepareArticleHolder];
	
	return ret;
}

-(void) endElement:(NSString*)name {
	//WebLink *link = currentLink;
	//NSLog(@"Link.text: %@", link.text);
	//NSLog(@"Link.url: %@", link.url);

	// re-initialize link so that we can add it later.
	//currentLink = nil;
	
	//return link;
}

- (void)dealloc
{
	//[text release];
	[super dealloc];
}


@end

@implementation RSSChannelState

- (void)parser 
{
	TRACE("RSSChannelState.\n");
}

+(RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssChannelInstance == nil) {
		rssChannelInstance = [[RSSChannelState alloc] initWithDelegate:delegate];
	}
	
	return rssChannelInstance;
}

-(BOOL) startElement 
{
	BOOL ret = YES;
	
	[parserDelegate prepareTitleHolder];
	
	return ret;
}

-(void) endElement:(NSString*)name 
{
	
}


@end


@implementation RSSTitleState

-(void) parse 
{
	TRACE("RSSTitleState.\n");
}

+(RSSParserState*) getInstance:(RSSParser*)delegate 
{
	if (rssTitleInstance == nil) {
		rssTitleInstance = [[RSSTitleState alloc] initWithDelegate:delegate];
	}
	
	return rssTitleInstance;
}

-(BOOL) startElement 
{
	elementEnded = NO;
	text = [[NSMutableString alloc] initWithCapacity:DEFAULT_MSG_SIZE];
	return YES;
}

-(void) addCharactersInText:(NSString*)string 
{
	if (elementEnded == NO) {
		[text appendString:string]; 
		//NSLog(@"Add title: %@", text);
	}
}

-(void) endElement:(NSString*)name 
{
	if (elementEnded == NO) {
		elementEnded = YES;
		[parserDelegate setArticleTitle:text];
		[text release];
		//NSLog(@"endElement: %@", text);
		//return nil;
	}
}

@end

@implementation RSSLinkState

-(void) parse {
	TRACE("RSSLinkState.\n");
}

+(RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssLinkInstance == nil) {
		rssLinkInstance = [[RSSLinkState alloc] initWithDelegate:delegate];
	}
	return rssLinkInstance;
}

-(BOOL) startElement {
	elementEnded = NO;
	text = [[NSMutableString alloc] initWithCapacity:DEFAULT_MSG_SIZE];
	return YES;
}

-(void) addCharactersInText:(NSString*)string {
	if (elementEnded == NO) {
		[text appendString:string]; 
		//NSLog(@"Add link: %@", text);

	}
}

-(void) endElement:(NSString*)name {
	if (elementEnded == NO) {
		elementEnded = YES;
		[parserDelegate setArticleURL:text];
		[text release];
		//NSLog(@"endElement: %@", text);
		//return nil;
	}
}

@end

@implementation RSSGUIDState

-(void) parse {
	TRACE("RSSGUIDState.\n");
}

+(RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssGUIDInstance == nil) {
		rssGUIDInstance = [[RSSGUIDState alloc] initWithDelegate:delegate];
	}
	return rssGUIDInstance;
}

-(BOOL) startElement {
	elementEnded = NO;
	return YES;
}

-(void) addCharactersInText:(NSString*)string {
	//if (elementEnded == NO) {
	//	currentLink.url = [currentLink.url stringByAppendingString:string];
	//}
}

-(void) endElement:(NSString*)name {
	elementEnded = YES;
	//return nil;
}

@end

@implementation RSSDescriptionState

- (void)parse {
	TRACE("RSSDescription.\n");
}

+ (RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssDescriptionInstance == nil) {
		rssDescriptionInstance = [[RSSDescriptionState alloc] initWithDelegate:delegate];
	}
	return rssDescriptionInstance;
}

-(BOOL) startElement 
{
	elementEnded = NO;
	text = [[NSMutableString alloc] initWithCapacity:DEFAULT_MSG_SIZE];
	return YES;
}

-(void) addCharactersInText:(NSString*)string 
{
	if (elementEnded == NO) {
		[text appendString:string]; 
		//NSLog(@"Add title: %@", text);
	}
}

-(void) endElement:(NSString*)name 
{
	if (elementEnded == NO) {
		elementEnded = YES;
		[parserDelegate setArticleDescription:text];
		[text release];
		//NSLog(@"endElement: %@", text);
		//return nil;
	}
}


@end

@implementation RSSBuildDateState

- (void)parser 
{
	TRACE("RSSBuildDateState.\n");
}

+(RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssBuildDateInstance == nil) {
		rssBuildDateInstance = [[RSSBuildDateState alloc] initWithDelegate:delegate];
	}
	
	return rssBuildDateInstance;
}

-(BOOL) startElement 
{
	BOOL ret = YES;
	
	elementEnded = NO;
	text = [[NSMutableString alloc] initWithCapacity:DEFAULT_MSG_SIZE];
	
	return ret;
}

-(void) addCharactersInText:(NSString*)string 
{
	if (elementEnded == NO) {
		[text appendString:string]; 
		//NSLog(@"Add title: %@", text);
	}
}

-(void) endElement:(NSString*)name 
{
	if (elementEnded == NO) {
		elementEnded = YES;
		[parserDelegate setBuildDate:text];
		[text release];
		//NSLog(@"endElement: %@", text);
		//return nil;
	}	
}


@end

@implementation RSSTTLState

- (void)parser 
{
	TRACE("RSSTTLState.\n");
}

+(RSSParserState*) getInstance:(RSSParser*)delegate {
	if (rssTTLInstance == nil) {
		rssTTLInstance = [[RSSTTLState alloc] initWithDelegate:delegate];
	}
	
	return rssTTLInstance;
}

-(BOOL) startElement 
{
	BOOL ret = YES;
	
	elementEnded = NO;
	text = [[NSMutableString alloc] initWithCapacity:DEFAULT_MSG_SIZE];
	
	return ret;
}

-(void) addCharactersInText:(NSString*)string 
{
	if (elementEnded == NO) {
		[text appendString:string]; 
		//NSLog(@"Add title: %@", text);
	}
}

-(void) endElement:(NSString*)name 
{
	if (elementEnded == NO) {
		elementEnded = YES;
		[parserDelegate setArticleTTL:[text integerValue]];
		[text release];
	}		
}


@end




