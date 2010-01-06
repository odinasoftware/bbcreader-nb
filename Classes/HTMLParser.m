//
//  HTMLParser.m
//  NYTReader
//
//  Created by Jae Han on 7/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HTMLParser.h"
#import "HTMLStream.h"
#import "ParserHandler.h"
#import	"WebCacheService.h"
#import "CacheEntry.h"
#import "SiteExpert.h"

char START_TAG='<';
char END_TAG='>';
char END_SLASH='/';
char CHAR_SPACE=' ';
char CHAR_ASSIGN='=';
char CHAR_NEWLINE=0x0a;
char CHAR_LINEFEED=0x0d;
char CHAR_TAB=0x09;
char CHAR_EXCL='!';
char CHAR_END_PARAN=')';
char CHAR_SEMI_COLON=';';

NSString* COMMENT_POSTFIX=@"--";
NSString* END_OF_COMMENT=@"-->";
NSString* HTTP_PREFIX=@"http://";
NSString* HTML_EXT=@".html";
NSString* SPACE_ENCODE = @"%20";
NSString* SCRIPT_END_TAG = @"</script>";
NSString* STYLE_END_TAG = @"</style>";
NSString* TYPE_ATTR = @"type";
NSString* END_LI_TOKEN = @"</li>";

NSString* IMPORT_STYLE_TOKEN = @"@import ";
NSString* CSS_URL_STYLE_TOKEN = @"url(";
NSString* CSS_URL_PREFIX = @"url(";
NSString* TITLE_ELE = @"title";
NSString* IMG_ELE = @"img";
NSString* TD_ELE = @"td";
NSString* SCRIPT_ELE = @"script";
NSString* LINK_ELE = @"link";
NSString* INPUT_ELE = @"input";
NSString* STYLE_ELE = @"style";
NSString* DIV_ELE = @"div";
NSString* IFRAME_ELE = @"iframe";
NSString* ANCHOR_ELE = @"a";
NSString* LI_ELE = @"li";
NSString* FORM_ELE = @"form";
NSString* SPAN_ELE = @"span";
NSString* DIV_END_ELE = @"/div";
NSString* ANCHOR_END_ELE = @"/a";
NSString* META_ELE = @"meta";
NSString* TABLE_BEGIN_ELE = @"table";
NSString* TABLE_END_ELE = @"/table";

NSString *META_NAME_TYPE = @"name";
NSString *META_CONTENT_TYPE = @"content";
NSString *CLASS_TYPE = @"class";
NSString *SRC_TYPE = @"src";
NSString *BACKGROUND_TYPE = @"background";
NSString *HREF_TYPE = @"href";
NSString *ACTION_TYPE = @"action";

NSString *HTML_TEXT_TYPE = @"html";
NSString *CSS_TEXT_TYPE = @"css";

//char* FILE_URL_PREFIX="file://";
char* FILE_URL_PREFIX="http://localhost:9000";

unichar toLowerCase(unichar c) {
	if ((c >= 'A') && (c <= 'Z')) {
		return c+32;
	}
	return c;
}

NSString* NSDataToString(NSData* x) {
	unsigned char* char_ptr = (unsigned char*)[x bytes];
	return [[NSString alloc] initWithBytes:char_ptr length:[x length] encoding:NSUTF8StringEncoding];
}

char CharFromNSDataAtIndex(NSData *x, int i) {
	unsigned char* char_ptr = (unsigned char*)[x bytes];
	if (i >= [x length]) {
		NSLog(@"%s, index error: %d %d", __func__, [x length], i);
		return -1;
	}
	
	return char_ptr[i];
}


@implementation HTMLParser

@synthesize charBuffer;
@synthesize tempBuffer;
@synthesize htmlStream;
@synthesize destStream;
@synthesize parserStatus;
@synthesize attrHandlerMap;
@synthesize linkType;
@synthesize baseURL;
@synthesize styleAttrHandlerMap;
@synthesize anchorAttrHandlerMap;
@synthesize cacheService;
@synthesize anchorOpen;
@synthesize divOpen;

- (id)init 
{
	if ((self = [super init])) {
		//destStream = [[NSMutableData alloc] init];
		htmlStream = [[HTMLStream alloc] init];
		// element key buffer, will not exceed 30.
		keyBuffer = [[NSMutableData alloc] initWithLength:30];
		tempBuffer = [[NSMutableData alloc] initWithLength:30];
		charBuffer = [[NSMutableData alloc] initWithLength:30];
		
		[self registerHandler];
		cacheService = nil;
		
		anchorOpen = NO;
		divOpen = NO;
		destStream = [[NSMutableData alloc] init];
		theSiteExpert = [[BBCSiteExpert alloc] initWithParser:self]; //[[NewYorkerSiteExpert alloc] initWithParser:self];
	}
	return self;
}

- (void)registerHandler
{
	TitleElementHandler *titleElementHander = [[TitleElementHandler alloc] initWithParser:self];
	ImgElementHandler *imgElementHandler = [[ImgElementHandler alloc] initWithParser:self];
	TDElementHandler *tdElementHandler = [[TDElementHandler alloc] initWithParser:self];
	LinkElementHandler *linkElementHandler = [[LinkElementHandler alloc] initWithParser:self];
	ScriptElementHandler *scriptElementHandler = [[ScriptElementHandler alloc] initWithParser:self];
	StyleElementHandler *styleElementHandler = [[StyleElementHandler alloc] initWithParser:self];
	DivElementHandler *divElementHandler = [[DivElementHandler alloc] initWithParser:self];
	IFrameElementHandler *iframeElementHandler = [[IFrameElementHandler alloc] initWithParser:self];
	AnchorElementHandler *anchorElementHandler = [[AnchorElementHandler alloc] initWithParser:self];
	FormElementHandler *formElementHandler = [[FormElementHandler alloc] initWithParser:self];
	MetaElementHandler *metaElementHandler = [[MetaElementHandler alloc] initWithParser:self];
	//TableBeginElementHandler *tableBeginElementHandler = [[tableBeginElementHandler alloc] initWithParser:self];
	TableEndElementHandler *tableEndElementHandler = [[TableEndElementHandler alloc] initWithParser:self];
	
	HrefAttrHandler *hrefAttrHandler = [[HrefAttrHandler alloc] initWithParser:self];
	
	SrcAttrHandler *srcAttrHandler = [[SrcAttrHandler alloc] initWithParser:self];
	
	TypeAttrHandler *typeAttrHandler = [[TypeAttrHandler alloc] initWithParser:self];
	
	StyleImportHandler *styleImportHandler = [[StyleImportHandler alloc] initWithParser:self];
	CssUrlHandler *cssUrlHandler = [[CssUrlHandler alloc] initWithParser:self];
	DivStyleAttrHandler *divStyleAttrHandler = [[DivStyleAttrHandler alloc] initWithParser:self];
	
	ClassAttrHandler *classAttrHandler = [[ClassAttrHandler alloc] initWithParser:self];
	
	DivEndElementHandler *divEndElementHandler = [[DivEndElementHandler alloc] initWithParser:self];
	AnchorEndElementHandler *anchorEndElementHandler = [[AnchorEndElementHandler alloc] initWithParser:self];
	
	MetaNameAttrHandler *metaNameAttrHandler = [[MetaNameAttrHandler alloc] initWithParser:self];
	MetaContentAttrHandler *metaContentAttrHandler = [[MetaContentAttrHandler alloc] initWithParser:self];
	
	// Element handler
	NSArray *keys = [[NSArray alloc] initWithObjects:TITLE_ELE, IMG_ELE, LINK_ELE, SCRIPT_ELE, TD_ELE, 
													 INPUT_ELE, STYLE_ELE, DIV_ELE, SPAN_ELE, IFRAME_ELE, 
													 LI_ELE, ANCHOR_ELE, FORM_ELE, DIV_END_ELE, ANCHOR_END_ELE, 
													 META_ELE, TABLE_END_ELE, nil];
	NSArray *handlers = [[NSArray alloc] initWithObjects:titleElementHander, imgElementHandler, linkElementHandler, scriptElementHandler, tdElementHandler,
														 imgElementHandler, styleElementHandler, divElementHandler, divElementHandler, iframeElementHandler,
														 divElementHandler, anchorElementHandler, formElementHandler, divEndElementHandler, anchorEndElementHandler, 
														 metaElementHandler, tableEndElementHandler, nil];
	handlerMap = [[NSDictionary alloc] initWithObjects:handlers forKeys:keys];
	[keys release];
	[handlers release];
	/*
	registerHandler(TITLE_ELE, mHandlerMap, mTitleElementHandler);
	registerHandler(, mHandlerMap, mImgElementHandler);
	registerHandler(LINK_ELE, mHandlerMap, mLinkElementHandler);
	registerHandler(SCRIPT_ELE, mHandlerMap, mScriptElementHandler);
	registerHandler(TD_ELE, mHandlerMap, mImgElementHandler);
	registerHandler(INPUT_ELE, mHandlerMap, mImgElementHandler);
	registerHandler(STYLE_ELE, mHandlerMap, mStyleElementHandler);
	registerHandler(DIV_ELE, mHandlerMap, mDivElementHandler);
	registerHandler(SPAN_ELE, mHandlerMap, mDivElementHandler);
	registerHandler(IFRAME_ELE, mHandlerMap, mIFrameElementHandler);
	registerHandler(LI_ELE, mHandlerMap, mDivElementHandler);
	registerHandler(ANCHOR_ELE, mHandlerMap, mAnchorElementHandler);
	registerHandler(FORM_ELE, mHandlerMap, mFormElementHandler);
	 */
	
	NSArray *anchorKey = [[NSArray alloc] initWithObjects:SRC_TYPE, nil];
	NSArray *anchorHandler = [[NSArray alloc] initWithObjects:hrefAttrHandler, nil];
	anchorAttrHandlerMap = [[NSDictionary alloc] initWithObjects:anchorHandler forKeys:anchorKey];
	[anchorKey release];
	[anchorHandler release];
	//registerHandler(SRC_TYPE, mAnchorAttrHandlerMap, mHrefAttrHandler);
	
	// Attributes handler
	NSArray *attrKeys = [[NSArray alloc] initWithObjects:BACKGROUND_TYPE, SRC_TYPE, HREF_TYPE, TYPE_ATTR, META_NAME_TYPE, 
														META_CONTENT_TYPE, CLASS_TYPE, nil];
	NSArray *attrHandler = [[NSArray alloc] initWithObjects:srcAttrHandler, srcAttrHandler, hrefAttrHandler, typeAttrHandler, 
														metaNameAttrHandler, metaContentAttrHandler, classAttrHandler, nil];
	attrHandlerMap = [[NSDictionary alloc] initWithObjects:attrHandler forKeys:attrKeys];
	[attrKeys release];
	[attrHandler release];
	/*
	registerHandler(BACKGROUND_TYPE, mAttrHandlerMap, mSrcAttrHandler);
	registerHandler(SRC_TYPE, mAttrHandlerMap, mSrcAttrHandler);
	registerHandler(HREF_TYPE, mAttrHandlerMap, mHrefAttrHandler);
	registerHandler(TYPE_ATTR, mAttrHandlerMap, mTypeAttrHandler);
	 */
	
	// Style tag handler
	NSArray *styleKeys = [[NSArray alloc] initWithObjects:IMPORT_STYLE_TOKEN, CSS_URL_STYLE_TOKEN, STYLE_ELE, CLASS_TYPE, nil];
	NSArray *styleHandlers = [[NSArray alloc] initWithObjects:styleImportHandler, cssUrlHandler, divStyleAttrHandler, classAttrHandler, nil];
	styleAttrHandlerMap = [[NSDictionary alloc] initWithObjects:styleHandlers forKeys:styleKeys];
	[styleKeys release];
	[styleHandlers release];
	/*
	registerHandler(IMPORT_STYLE_TOKEN, mStyleAttrHandlerMap, mStyleImportHandler);
	registerHandler(CSS_URL_STYLE_TOKEN, mStyleAttrHandlerMap, mCSSUrlHandler);
	registerHandler(STYLE_ELE, mStyleAttrHandlerMap, mDivStyleAttrHandler);
	 */
}

- (NSString*)stripUrl:(NSMutableData*)href
{
	int match=0;
	BOOL not_part_of = NO;
	int data = -1;
	//NSMutableString *strippedURL = [[NSMutableString alloc] init];
	
	//mCharBuffer.clear();
	[tempBuffer setLength:0];

	for (int i=0; i<[href length]; ++i){
		data = CharFromNSDataAtIndex(href, i);
		if ((data == '"') || (data == '\'')) {
			match++;
		}
		
		switch (data) {
			case '"':
			case ' ':
			case '\'':
			case '>':
			case '\r':
			case '\n':
				//			case ')':
				//			case '(':
				not_part_of = YES;
				break;
			case '/':
				if (match == 2) {
					// only when we detect the matching quotation. 
					not_part_of = YES;
				}
				else
					not_part_of = NO;
				break;
			default:
				not_part_of = NO;
		}
		
		if (not_part_of == NO) {
			//mCharBuffer.put(href.charAt(i));
			//data = [href characterAtIndex:i];
			//[strippedURL appendFormat:@"%c",(char)data];
			[tempBuffer appendBytes:&data length:1];
		}
		
	}
	
	//mCharBuffer.flip();
	
	//return strippedURL;
	return [[NSString alloc] initWithBytes:[tempBuffer bytes] length:[tempBuffer length] encoding:NSUTF8StringEncoding];
}

- (void)rollbackTokens:(int)bytes
{
	[destStream setLength:[destStream length]-bytes];
}

- (BOOL)takeOut2thisToken:(NSString*)token
{
	int data=-1;
	int found=0;
	BOOL ret = NO;
	int count=0;
	
	while ((data = [htmlStream readFromStream]) != -1) {
		//char c = java.lang.Character.toLowerCase((char) data);
		char c = toLowerCase(data);
		if (c == [token characterAtIndex:found]) {
			found++;
		}
		else {
			found=0;
		}
		
		//mBufferedStream.write(data);
		//[destStream appendBytes:&data length:1];
		
		if (found == [token length]) {
			//NSLog(@"skip2thisToken: found token, %@, skipped: %d",token, count);
			ret = YES;
			break;
		}
		count++;
	}
	
	return ret;
}
- (BOOL)skip2thisToken:(NSString*)token
{
	int data=-1;
	int found=0;
	BOOL ret = NO;
	int count=0;

	while ((data = [htmlStream readFromStream]) != -1) {
		//char c = java.lang.Character.toLowerCase((char) data);
		char c = toLowerCase(data);
		if (c == [token characterAtIndex:found]) {
			found++;
		}
		else {
			found=0;
		}
		
		//mBufferedStream.write(data);
		[destStream appendBytes:&data length:1];
		
		if (found == [token length]) {
			//NSLog(@"skip2thisToken: found token, %@, skipped: %d",token, count);
			ret = YES;
			break;
		}
		count++;
	}

	return ret;
}

- (void)write2StreamWithData:(int)data
{
	/*
	for (int i=0; i<mCharBuffer.length(); ++i) {
		mBufferedStream.write(mCharBuffer.charAt(i));
	}
	mBufferedStream.write((char)data);
	 */
	
	[destStream appendBytes:[charBuffer bytes] length:[charBuffer length]];
	[destStream appendBytes:&data length:1];
}

- (void)write2Stream
{	
	/*
	for (int i=0; i<mCharBuffer.length(); ++i) {
		mBufferedStream.write(mCharBuffer.charAt(i));
	}
	 */
	[destStream appendBytes:[charBuffer bytes] length:[charBuffer length]];
}

- (BOOL)skip2nextToken
{
	BOOL canContinue = NO;
	int data=-1;

	while ((data = [htmlStream readFromStream]) != -1) {
		if ((data == CHAR_SPACE) || (data == END_TAG)) {
			//mBufferedStream.write(data);
			[destStream appendBytes:&data length:1];
			if (data == END_TAG) {
				parserStatus = PARSER_END_ELE;
			}
			break;
		}
		//mBufferedStream.write(data);
		[destStream appendBytes:&data length:1];
	}
	
	if (data == CHAR_SPACE)
		canContinue = YES; // can continue
	else
		canContinue = NO; // can't continue
	
	return canContinue;
}

- (BOOL)skip2thisPatternToken:(NSString*)token 
{
	int data=-1;
	int found=0;
	BOOL ret = NO;
	int prefix_len = [token length]-1;
	unichar t = [token characterAtIndex:([token length] - 1)]; // get the last character
	
	int count=0;
		
	//mTempBuffer.clear();
	[tempBuffer setLength:0];
	
	while ((data = [htmlStream readFromStream]) != -1) {
		int c = toLowerCase(data);
		if (c != t) {
			if ([tempBuffer length] >= prefix_len) {
				[tempBuffer setLength:0];
				//mTempBuffer.clear();
			}
			[tempBuffer appendBytes:(const void*)&c length:1];
			//mTempBuffer.put(c);
		}
		
		//mBufferedStream.write(data);
		[destStream appendBytes:(const void*)&data length:1];
		
		if (c == t) {
			//mTempBuffer.flip();
			int s = [tempBuffer length]; //mTempBuffer.limit();
			found = 1;
			char *tempData = (char*) [tempBuffer bytes];
			for (int i=0, j=0; (i<s && j<prefix_len); ++i, ++j) {
				// TODO: make sure this pointer comparision is right
				if (tempData[i] != [token characterAtIndex:j]) {
					// they are not same.
					//mTempBuffer.clear();
					[tempBuffer setLength:0];
					found = 0;
					break;
				}
			}
			if (found == 1) {
				//NSLog(@"skip2thisToken: found token %@, skipped: %d", token, count);
				ret = YES;
				break;
			}
		}
		count++;
	}
	
	
	return ret;
}

- (NSMutableData*)getThisToken
{
	int data;
	NSMutableData *found = nil;
	//mCharBuffer.clear();
	[charBuffer setLength:0];

	while ((data = [htmlStream readFromStream]) != -1) {
		if ((data == CHAR_SPACE) || (data == END_TAG)) {
			//mCharBuffer.put((char) data);
			[charBuffer appendBytes:&data length:1];
			//mCharBuffer.flip();
			found = charBuffer;
			if (data == END_TAG) {
				parserStatus = PARSER_END_ELE;
			}
			break;
		}
		//mCharBuffer.put((char)data);
		[charBuffer appendBytes:&data length:1];
	}
	
	return found;
}

- (NSMutableData*)findAttribute
{
	NSMutableData *found = nil;
	
	//mCharBuffer.clear();
	[charBuffer setLength:0];
	int data;

	while ((data = [htmlStream readFromStream]) != -1) {
		if (data == END_TAG){
			// Tag end without attribute
			
			//mCharBuffer.flip();
			
			[self write2StreamWithData:data];
			
			
			parserStatus = PARSER_END_ELE;
			break;
		} else if (data == CHAR_ASSIGN) {
			//mCharBuffer.flip();
			
			[self write2StreamWithData:data];
			
			//moveToKeyBuffer();
			found = charBuffer;
			break;
		} else if ((data == CHAR_SPACE) || 
				   (data == CHAR_LINEFEED) || 
				   (data == CHAR_NEWLINE) ||
				   (data == CHAR_TAB)){
			// this must space separator, we will look for more space
			//mCharBuffer.flip();
			
			[self write2StreamWithData:data];
			
			break;
		}
		//mCharBuffer.put((char)data);
		[charBuffer appendBytes:&data length:1];
	}
		
	return found;
}

- (BOOL)canConnectThisToken:(NSString*)token canIgnoreBlank:(BOOL)ignore_blank 
{
	BOOL detected = NO;
	int found = 0;
	int data=-1;
	
	@try {
		while ((data = [htmlStream readFromStream]) != -1) {
			unichar c = toLowerCase(data);
			
			if (c == [token characterAtIndex:found]) {
				found++;
			}
			else {
				found=0;
			}
			
			// TODO: Data is int type and this is passed as a pointer. Can this work?
			[destStream appendBytes:(const void*)&data length:1];
			//mBufferedStream.write(data);
			
			if (found == [token length]) {
				detected = YES;
				break;
			}
			else if (ignore_blank && (data == CHAR_SPACE)) {
				found = 0;
				continue;
			} else if (found == 0) {
				detected = NO;
				break;
			}
		}
	} 
	@catch (NSException* e) {
		NSLog(@"detectThisToken: %@", [e reason]);
	}
	
	return detected;
}

- (int)getImportUrlToken
{
	int data;
	int ret=-1;
	BOOL add = YES;
	int i = 0;
	
	//mCharBuffer.clear();
	[charBuffer setLength:0];

	while ((data = [htmlStream readFromStream]) != -1) {
		if ((data == '"') || (data == '\'')) {
			if (i > 0) {
				// delimiter case
				//mCharBuffer.flip();
				ret = data;
				break;
			}
			else {
				// beginning indicator
				//mBufferedStream.write((char) data);
				[destStream appendBytes:&data length:1];
				add = NO;
			}
		}
		else if ((data == CHAR_SEMI_COLON) || (data == CHAR_END_PARAN)) {
			// we will append it later
			//mCharBuffer.flip();
			ret = data;
			break;
		}
		
		if (add == YES) {
			++i;
			//mCharBuffer.put((char)data);
			[charBuffer appendBytes:&data length:1];
		}
		else {
			// next time, we will add.
			add = YES;
		}
	}
	
	return ret;
}

- (BOOL)findThisTokenWithQuote:(NSString*)token withEndTag:(NSString*)end_tag
{
	int data=-1;
	int pattern=0;
	char match_quote = '"';
	BOOL begin = NO;
	BOOL found_token = NO;
	int end=0;

	while ((data = [htmlStream readFromStream]) != -1) {
		if (begin == NO) {
			if (data == '\'') {
				match_quote = '\'';
				begin = YES;
				continue;
			} else if (data == '"') {
				begin = YES;
				continue;
			}
		} 
		
		if (begin) {
			//char c = java.lang.Character.toLowerCase((char) data);
			char c = toLowerCase(data);
			if (c == match_quote) {
				break;
			} else if (c == [token characterAtIndex:pattern]) {
				pattern++;
			} else {
				pattern=0;
			}
		}
		
		if ([end_tag characterAtIndex:end] == data) {
			end++;
		}
		else
			end = 0;
		
		//mBufferedStream.write(data);
		[destStream appendBytes:&data length:1];
		
		if (pattern == [token length]) {
			//					Log.i(TAG, "findThisToken: found token, " + token);
			found_token = YES;
			break;
		} else if (end == [end_tag length]) {
			// end tag was seen, stop now.
			found_token = NO;
			break;
		}
		
	}
	
	return found_token;
}

- (NSMutableData*)findElementString
{
	NSMutableData *found=nil;
	//int hash_code=-1;
	//CharBuffer buffer = CharBuffer.allocate(DEFAULT_CHAR_BUFFER_CAP);
	[charBuffer setLength:0]; //mCharBuffer.clear();
	int data;
	
	@try {
		//Log.d(TAG, "read");
		//mInBufSize = mInput.read(minBuf, 0, MAX_IN_BUF_SIZE);
		while ((data = [htmlStream readFromStream]) != -1) {
			//for (int n=0; n<mInBufSize; ++n) {
			//data = minBuf[n];
			
			if (data == CHAR_EXCL) {
				// comment starts
				//mBufferedStream.write(data);
				[destStream appendBytes:&data length:1];
				if ([self canConnectThisToken:COMMENT_POSTFIX canIgnoreBlank:NO]) {
					// This may not really right syntatically, but
					// this should be fine pratically.
					[self skip2thisPatternToken:END_OF_COMMENT];
					//skip2TokenWithPrefix(">", "--");
				}
				break;
			}
			
			if ((data == CHAR_LINEFEED) || (data == CHAR_NEWLINE) || (data == CHAR_SPACE) || (data == END_TAG)) {
				
				//mCharBuffer.flip();
				[self write2StreamWithData:data];
				
				
				//mBufferedStream.write(s.getBytes());
				if (data == CHAR_SPACE){
					// TODO: do we need this parser status.
					//mParserStatus = PARSER_START_ELE;
				} else if (data == END_TAG){
					//mParserStatus = PARSER_END_ELE;
				}
				//moveToKeyBuffer();
				//found = true;
				found = charBuffer;
				
				break;
			}
			//mCharBuffer.put((char)data);
			[charBuffer appendBytes:&data length:1];
		}
		
	} 
	@catch(NSException *e){
		NSLog(@"findElementString: %@", [e reason]);
	} 
	
	//return hash_code;
	return found;
}

- (void)startElement:(int)level
{
	// Detect start element, see if it is one of embedded tag
	NSMutableData *found = [self findElementString];
	
	if (found == nil) {
		return;
	}
	//Log.i(TAG, "Element: " + mKeyBuffer.toString());
	NSString *key = NSDataToString(found);
	//NSLog(@"startElement: %@", key);
	ParserHandler *handler = [handlerMap objectForKey:key];
	[key release];
	
	if (handler != nil){
		//Log.i(TAG, "Element: " + mKeyBuffer.toString());		
		[handler OnElementAction:level];
	}
	else {
		// Just stream to output
		//mBufferedStream.write(element.getBytes());
		//mBufferedStream.write(CHAR_SPACE);
		//Log.i(TAG, "No handler: " + element);
	}
	
}

- (void)importUrl:(int)level
{
	if ([self canConnectThisToken:@"import" canIgnoreBlank:NO]) {
		ParserHandler *parserHandler = [styleAttrHandlerMap objectForKey:IMPORT_STYLE_TOKEN];
		[parserHandler OnElementAction:level];
	}
}

- (BOOL)findThisToken:(NSString*)token withEndTag:(NSString*)end_tag
{
	int data=-1;
	int pattern=0;
	int end = 0;
	BOOL found_token = NO;

	while ((data = [htmlStream readFromStream]) != -1) {
		//char c = java.lang.Character.toLowerCase((char) data);
		char c = toLowerCase(data);
		if (c == [token characterAtIndex:pattern]) {
			pattern++;
		} else if (c == [end_tag characterAtIndex:end]) {
			end++;
		} else {
			pattern=0;
			end=0;
		}
		
		//mBufferedStream.write(data);
		[destStream appendBytes:&data length:1];
		
		if (pattern == [token length]) {
			//Log.i(TAG, "findThisToken: found token, " + token);
			found_token = YES;
			break;
		} else if (end == [end_tag length]) {
			//Log.i(TAG, "findThisToken: reach end.");
			found_token = NO;
			break;
		}
	}
	
	return found_token;
}

- (void)getCSSUrl:(int)level
{
	while ([self findThisToken:CSS_URL_PREFIX withEndTag:@"}"]) {
		// found url inside CSS
		
		//mCSSUrlHandler.OnElementAction(level);
		ParserHandler *parserHandler = [styleAttrHandlerMap objectForKey:CSS_URL_STYLE_TOKEN];
		[parserHandler OnElementAction:level];
		
	}
}

- (void)parseCSS:(int)level withEndTag:(NSString*)end_tag
{
	int data;
	int found=0;
	
	while ((data = [htmlStream readFromStream]) != -1) {
		//mBufferedStream.write(data);
		[destStream appendBytes:&data length:1];
		switch (data){
			case '@':
				parserStatus = PARSER_START_AT;
				//importUrl(level);
				[self importUrl:level];
				break;
			case '{':
				parserStatus = PARSER_START_BRACE;
				//getCSSUrl(level);
				[self getCSSUrl:level];
				break;
			case '}':
				parserStatus = PARSER_END_BRACE;
				break;
			default:
				if ((end_tag != nil) && ([end_tag characterAtIndex:found] == data)) {
					found++;
				}
				else
					found=0;
		}
		
		if ([end_tag length] == found) {
			// Found the end tag, stop parsing
			//NSLog(@"parseCSS, end tag found.");
			break;
		}
	}
}

- (void)parseCSS:(int)level
{
	int data;
	
	while ((data = [htmlStream readFromStream]) != -1) {
		//mBufferedStream.write(data);
		[destStream appendBytes:&data length:1];
		switch (data){
			case '@':
				parserStatus = PARSER_START_AT;
				[self importUrl:level];
				break;
			case '{':
				parserStatus = PARSER_START_BRACE;
				[self getCSSUrl:level];
				break;
			case '}':
				parserStatus = PARSER_END_BRACE;
				break;
		}
	}
}

- (void)parseHTMLData:(NSData*)data
{
	int readData;
	int level = 0;
	
	
	[htmlStream setupStream:data];
	[destStream setLength:0];
	
	@try {
		while ((readData = [htmlStream readFromStream]) != -1) {
			//mBufferedStream.write(data);
			[destStream appendBytes:&readData length:1];
			//void *testBytes = [destStream bytes];
			//int len = [destStream length];
			
			switch (readData){
				case '<':
					parserStatus = PARSER_START_ELE;
					[self startElement:level];
					break;
				case '>':
					parserStatus = PARSER_END_ELE;
					break;
				case '/':
					
					break;
			}
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
}

- (void)parse:(NSData*)data withCache:(WebCacheService*)service withCacheEntry:(CacheEntry*)entry atIndexPath:(NSIndexPath*)indexPath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	cacheService = service;
	currentCacheEntry = entry;
	[entry retain];
	
	[theSiteExpert startSiteExpert:indexPath];
	
	[self parseHTMLData:data];
	
	// TODO: The parsing finished, do the post processings.
	//   1. save the destination stream
	//   2. flush embedded objects
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager createFileAtPath:getActualPath(entry.cacheFile) contents:destStream attributes:nil] == NO) {
		NSLog(@"%s, fail to create file: %@", __func__, entry.cacheFile);
	}
	
	[theSiteExpert stopSiteExpert];
	[self resetParser];
	[entry release];
	[pool release];
}

- (void)cleanupParserHandler:(NSDictionary*)dict
{
	NSEnumerator *enumerator = [dict keyEnumerator];
	id key;
	
	while ((key = [enumerator nextObject])) {
		ParserHandler *handler = [dict objectForKey:key];
		[handler release];
	}
	[dict release];	
}

- (void)unregisterHandler 
{
	[self cleanupParserHandler:handlerMap];
	[self cleanupParserHandler:anchorAttrHandlerMap];
	[self cleanupParserHandler:attrHandlerMap];
	[self cleanupParserHandler:styleAttrHandlerMap];
}

- (void)setCurrentClassName:(NSString*)class_name
{
	theCurrentClassName = class_name;
}

- (void)setBaseUrl:(NSURL*)base
{
	int count=0;
	int dot=0;
	int insert=0;
	NSString *url = [base absoluteString];
	
	for (int i=0; i<[url length]; ++i) {
		if ([url characterAtIndex:i] == '/')
			count++;
		else if ([url characterAtIndex:i] == '.')
			dot++;
		if (count == 3) {
			insert=i;
			break;
		}
	}

	if (count > 2) 
		baseURL = [url substringToIndex:insert+1];
	else
		baseURL = url;
	
}

- (void)resetClassName
{
	[theCurrentClassName release];
	theCurrentClassName = nil;
}

- (void)resetParser 
{
	[theSiteExpert resetKnowledge];
	[theCurrentClassName release];
	//[destStream setLength:0];
	theCurrentClassName = nil;
}

- (BOOL)setSiteKnowledge:(id)value withExtra:(id)extra forKey:(id)key
{
	return [theSiteExpert setSiteKnowledge:value withExtra:extra forKey:key];
}

- (BOOL)querySiteKnowledgeWithKey:(id)key
{
	return [theSiteExpert querySiteKnowledgeWithKey:key];
}

- (BOOL)querySiteKnowledgeWithKey:(id)key withValue:(id)value
{
	return [theSiteExpert querySiteKnowledgeWithKey:key withValue:value];
}

- (void)dealloc {
	//[baseURL release];
	[htmlStream release];
	[keyBuffer release];
	[tempBuffer release];
	[charBuffer release];
	
	[self unregisterHandler];
	[cacheService release];
	
	[super dealloc];
}

@end
