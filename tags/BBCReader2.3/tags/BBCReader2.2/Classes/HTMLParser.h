//
//  HTMLParser.h
//  NYTReader
//
//  Created by Jae Han on 7/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MReader_Defs.h"

@class HTMLStream;
@class WebCacheService;
@class CacheEntry;
@class SiteExpert;

typedef enum {PARSER_UNDEFINED, PARSER_START_ELE, PARSER_END_ELE, PARSER_START_AT, PARSER_START_BRACE, PARSER_END_BRACE} ParserStatusEnum;
typedef enum {NO_PARSER, HTML_PARSER, CSS_PARSER} ParserTypeEnum;
	
@interface HTMLParser : NSObject {
	 
	NSMutableData	*destStream;
	HTMLStream		*htmlStream;
	NSMutableData	*keyBuffer;
	NSMutableData	*tempBuffer;
	NSMutableData	*charBuffer;
	ParserStatusEnum parserStatus;
	ParserTypeEnum  linkType;
	
	NSDictionary	*handlerMap;
	NSDictionary	*attrHandlerMap;
	NSDictionary	*styleAttrHandlerMap;
	NSDictionary	*anchorAttrHandlerMap;
	
	NSString		*baseURL;
	WebCacheService *cacheService;
	CacheEntry		*currentCacheEntry;
	
	NSString		*theCurrentClassName;
	BOOL			divOpen;
	BOOL			anchorOpen;
	SiteExpert		*theSiteExpert;
}

@property (nonatomic, retain) NSMutableData *charBuffer;
@property (nonatomic, retain) NSMutableData *tempBuffer;
@property (nonatomic, retain) HTMLStream *htmlStream;
@property (nonatomic, retain) NSMutableData *destStream;
@property (nonatomic, assign) ParserStatusEnum parserStatus;
@property (nonatomic, assign) ParserTypeEnum linkType;
@property (nonatomic, retain) NSString *baseURL;

@property (nonatomic, retain) NSDictionary *attrHandlerMap;
@property (nonatomic, retain) NSDictionary *styleAttrHandlerMap;
@property (nonatomic, retain) NSDictionary *anchorAttrHandlerMap;
@property (nonatomic, retain) WebCacheService *cacheService;

@property (nonatomic, assign) BOOL divOpen;
@property (nonatomic, assign) BOOL anchorOpen;

//-(void) requestWithURLUseCache:(NSURL*) url delegate:(id)delegate parserKind:(MReaderParserType)type feedIndex:(NSInteger)index shouldWait:(BOOL)wait;
- (void)registerHandler;
- (NSString*)stripUrl:(NSMutableData*)href;
- (BOOL)skip2nextToken;
- (BOOL)skip2thisToken:(NSString*)token;
- (BOOL)skip2thisPatternToken:(NSString*)token;
- (BOOL)canConnectThisToken:(NSString*)token canIgnoreBlank:(BOOL)ignore_blank;
- (NSMutableData*)findAttribute;
- (NSMutableData*)findElementString;
- (void)write2StreamWithData:(int)data;
- (void)write2Stream;
- (int)getImportUrlToken;
- (BOOL)findThisTokenWithQuote:(NSString*)token withEndTag:(NSString*)end_tag;
- (NSMutableData*)getThisToken;
- (void)startElement:(int)level;
- (void)setBaseUrl:(NSURL*)base;

- (BOOL)setSiteKnowledge:(id)value withExtra:(id)extra forKey:(id)key;
- (void)importUrl:(int)level;
- (BOOL)findThisToken:(NSString*)token withEndTag:(NSString*)end_tag;
- (void)resetParser;
- (void)setCurrentClassName:(NSString*)class_name;
- (void)getCSSUrl:(int)level;
- (void)parseCSS:(int)level withEndTag:(NSString*)end_tag;
- (void)parseCSS:(int)level;
- (void)parseHTMLData:(NSData*)data;
- (void)parse:(NSData*)data withCache:(WebCacheService*)service withCacheEntry:(CacheEntry*)entry atIndexPath:(NSIndexPath*)indexPath;
- (BOOL)querySiteKnowledgeWithKey:(id)key;
- (BOOL)querySiteKnowledgeWithKey:(id)key withValue:(id)value;
- (BOOL)takeOut2thisToken:(NSString*)token;
- (void)rollbackTokens:(int)bytes;

@end
