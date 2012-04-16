//
//  ParserHandler.m
//  NYTReader
//
//  Created by Jae Han on 7/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ParserHandler.h"
#import "HTMLParser.h"
//#import "HTTPHelper.h"
#import "Parser_Defs.h"
#import "HTMLStream.h"
#import "WebCacheService.h"

// Indicate whether a parser handler can continue at some point.
// Ex., inside element and try to find an attribute
static BOOL canContinue = NO;

NSString* relativeStringToURL(NSString *relativeURL, NSString *base)
{
	// TODO: Both approach will either leak in autorelease pool or crash in the pool
	
	NSURL* base_url = [[NSURL alloc] initWithString:base];
	NSURL* absolute_url = [[NSURL alloc] initWithString:relativeURL relativeToURL:base_url];
	NSString* url_string = [absolute_url absoluteString];
	[base_url release];
	[absolute_url release]; 

	/*
	CFURLRef baseref = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)base, nil);
	CFURLRef url = CFURLCreateAbsoluteURLWithBytes(kCFAllocatorDefault, (const UInt8*)[relativeURL UTF8String], [relativeURL length], 
												   kCFStringEncodingUTF8, baseref, true);
	CFRelease(baseref);
	NSString* url_string = [(NSURL*)url absoluteString];
	// TODO: Releasing this will crash pool.
	CFRelease(url); 
	*/
	
	
	//NSString *url_string = [base stringByAppendingPathComponent:relativeURL];
	//NSString *url_string = [base stringByAppendingString:relativeURL];
	
	[relativeURL release]; // don't need this anymore because we are returning new one here.
	if (absolute_url == nil) {
		NSLog(@"%s, absolute url is nil.", __func__);
	}
	
	return url_string;
}

@implementation ParserHandler

@synthesize currentLevel;

- (id)initWithParser:(HTMLParser*)parser;
{
	if ((self = [super init])) {
		theParser = parser;
	}
	return self;
}

- (void)OnElementAction:(int)level
{
}

- (void)OnFilterAction:(NSString*)local byURL:(NSString*)url
{
	return;
}

- (void)OnPageAction
{
	return;
}

- (void)dealloc {
	[super dealloc];
}

@end

@implementation TitleElementHandler

- (void)OnElementAction:(int)level
{
	// found title, get the title and prepare file stream.
	int data;
	NSString *name;
	
	//NSLog(@"%s", __func__);
	//mCharBuffer.clear();
	[theParser.charBuffer setLength:0];
	
	@try {
		while ((data = [theParser.htmlStream readFromStream]) != -1) {
			if (data == START_TAG) {
				//mCharBuffer.flip();
				//name = mCharBuffer.toString();
				name = NSDataToString(theParser.charBuffer);
				/* TODO: implement title handler
				 if (mTitleReceiver != null) {
				 mTitleReceiver.OnReceiveTitle(name);
				 // We only will receiver the title from the first page.
				 mTitleReceiver = null;
				 }
				 */
				[theParser write2StreamWithData:data];
				[name release];
				
				break;
			}
			//mCharBuffer.put((char)data);
			[theParser.charBuffer appendBytes:&data length:1];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
		
}

@end

@implementation ImgElementHandler

- (void)OnElementAction:(int)level
{
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	//NSLog(@"%s", __func__);
	BOOL cont = YES;

	@try {
		do {
			NSMutableData *found = [theParser findAttribute];
			
			//Log.d(TAG, "Img: " + mCharBuffer.toString());
			if (found) {

				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.attrHandlerMap objectForKey:key];
				//NSLog(@"img attr: %@", key);
				[key release];
				if (handler != nil){
					//Log.d(TAG, "Img: " + mKeyBuffer.toString());		
					//handler.OnElementAction(level);
					[handler OnElementAction:level];
					
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					//Log.d(TAG, "Img2: " + mCharBuffer.toString());
					cont = [theParser skip2nextToken];
				}
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

@end

@implementation TDElementHandler

- (void)OnElementAction:(int)level
{
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	//NSLog(@"%s", __func__);
	BOOL cont = YES;
	
	@try {
		do {
			NSMutableData *found = [theParser findAttribute];
			
			//Log.d(TAG, "Img: " + mCharBuffer.toString());
			if (found) {
				
				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.attrHandlerMap objectForKey:key];
				//NSLog(@"img attr: %@", key);
				[key release];
				if (handler != nil){
					//Log.d(TAG, "Img: " + mKeyBuffer.toString());		
					//handler.OnElementAction(level);
					[handler OnElementAction:level];
					
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					//Log.d(TAG, "Img2: " + mCharBuffer.toString());
					cont = [theParser skip2nextToken];
				}
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

@end

@implementation TableEndElementHandler

- (void)OnElementAction:(int)level
{
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	//NSLog(@"%s", __func__);
	BOOL cont = YES;
	
	@try {
		do {
			[theParser setSiteKnowledge:nil withExtra:nil forKey:@"/table"];
			NSMutableData *found = [theParser findAttribute];
			
			//Log.d(TAG, "Img: " + mCharBuffer.toString());
			if (found) {
				
				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.attrHandlerMap objectForKey:key];
				//NSLog(@"img attr: %@", key);
				[key release];
				if (handler != nil){
					//Log.d(TAG, "Img: " + mKeyBuffer.toString());		
					//handler.OnElementAction(level);
					[handler OnElementAction:level];
					
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					//Log.d(TAG, "Img2: " + mCharBuffer.toString());
					cont = [theParser skip2nextToken];
				}
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

@end


@implementation LinkElementHandler

- (void)OnElementAction:(int)level
{
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	//NSLog(@"%s", __func__);
	theParser.linkType = NO_PARSER;
	BOOL cont = YES;
	
	@try {
		do {
			NSMutableData *found = [theParser findAttribute];
			
			if (found) {
				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.attrHandlerMap objectForKey:key];
				[key release];
				if (handler != nil){
					//Log.i(TAG, "Link: " + mKeyBuffer.toString());
					[handler OnElementAction:level];
					
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					cont = [theParser skip2nextToken];
				}
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
	
}

@end

@implementation ScriptElementHandler

- (void)OnElementAction:(int)level
{
	// found image tag, need to find src attribute
	//if (mParserStatus == PARSER_END_ELE) {
	// There are no attributes, no need to look more.
	//return;
	//}
	//Log.d(TAG, "Script tag detected.");
	//NSLog(@"%s", __func__);
	
	//[theParser skip2thisToken:SCRIPT_END_TAG];
	[theParser rollbackTokens:strlen("<script ")];
	[theParser takeOut2thisToken:SCRIPT_END_TAG];
}

@end

@implementation StyleElementHandler

- (void)OnElementAction:(int)level
{	
	BOOL cont = YES;

	//NSLog(@"%s", __func__);
	@try {
		do {
			if (theParser.parserStatus == PARSER_END_ELE) {
				// detect the end of element, now start look at inside
				//parseCSS(mLevel, STYLE_END_TAG);
				[theParser parseCSS:currentLevel withEndTag:STYLE_END_TAG];
				// stop after this. 
				cont = NO;
			} else {
				NSMutableData *found = [theParser findAttribute];
				
				if (found) {
					NSString *key = NSDataToString(found);
					ParserHandler *handler = [theParser.styleAttrHandlerMap objectForKey:key];
					[key release];
					if (handler != nil){
						//Log.i(TAG, "Style: " + mKeyBuffer.toString());
						[handler OnElementAction:level];
						cont = NO;
					} else {
						[theParser skip2nextToken];
					}
					
				}
			}
		} while (cont);
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

@end

@implementation DivElementHandler

- (void)OnElementAction:(int)level
{
	//NSLog(@"%s", __func__);
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	BOOL cont = NO;

	@try {
		do {
			theParser.divOpen = YES;
			NSMutableData *found = [theParser findAttribute];
			
			if (found) {
				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.styleAttrHandlerMap objectForKey:key];
				[key release];
				if (handler != nil){
					//Log.i(TAG, "Div: " + mKeyBuffer.toString());
					[handler OnElementAction:level];
					cont = NO;
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					cont = [theParser skip2nextToken];
				}
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	

}

@end

@implementation IFrameElementHandler

- (void)OnElementAction:(int)level
{
	//NSLog(@"%s", __func__);
	// we will only look at inside of the element.
	if (theParser.parserStatus == PARSER_END_ELE) {
		return;
	}
	BOOL cont = YES;
	
	@try {
		
		do {
			// In iframe we assume we will have html document.
			theParser.linkType = HTML_PARSER;
			NSMutableData *found = [theParser findAttribute];
			
			if (found) {
				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.anchorAttrHandlerMap objectForKey:key];
				[key release];
				if (handler != nil){
					//Log.i(TAG, "IFrame: " + mKeyBuffer.toString());		
					[handler OnElementAction:level];
					
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					cont = [theParser skip2nextToken];
				}
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	

}

@end


@implementation AnchorElementHandler

- (void)OnElementAction:(int)level
{
	//NSLog(@"%s", __func__);
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	BOOL cont = YES;
	theParser.linkType = NO_PARSER;

	@try {
		theParser.anchorOpen = YES;
		do {
			NSMutableData *found = [theParser findAttribute];
			
			//Log.d(TAG, "A Href: " + mCharBuffer.toString());
			if (found) {
				NSString *key = NSDataToString(found);
				
				//if (mKeyBuffer.toString().compareTo(HREF_TYPE) == 0) {
				if ([key compare:HREF_TYPE] == NSOrderedSame) {
					//Log.d(TAG, "A Href: " + mKeyBuffer.toString());
					//ParserHandler *handler = [
					//mAnchorHrefHandler.OnElementAction(level);
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					//Log.d(TAG, "A Href2: " + mCharBuffer.toString());
					cont = [theParser skip2nextToken];
				}
				[key release];
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}


@end

@implementation FormElementHandler

- (void)actionTypeHandler:(int)level
{
	char last_char = ' ';
	currentLevel = level;
	//NSLog(@"%s", __func__);
	
	@try {
		NSMutableData *found = [theParser getThisToken];
		if (found && ([found length]>0)){
			
			//last_char = mCharBuffer.charAt(mCharBuffer.length()-1);
			last_char = CharFromNSDataAtIndex(found, [found length]-1);
			
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			char data = '"';
			[theParser.destStream appendBytes:&data length:1];
			//write2Stream();
			//[local_name getCharacters:(unichar*)bytePtr];
			[theParser.destStream appendData:[stripped_href dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			[theParser.destStream appendBytes:&data length:1];
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			[stripped_href release];
			
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

- (void)OnElementAction:(int)level
{
	BOOL cont = YES;
	//NSLog(@"%s", __func__);
	
	@try {
		do {
			NSMutableData *found = [theParser findAttribute];
			
			if (found) {
				NSString *key = NSDataToString(found);
				//if (mKeyBuffer.toString().compareTo(ACTION_TYPE) == 0) {
				if ([key compare:ACTION_TYPE] == 0) {
					//mActionTypeHandler.OnElementAction(level);
					[self actionTypeHandler:level];
				} else if (theParser.parserStatus != PARSER_END_ELE) {
					cont = [theParser skip2nextToken];
				}
				[key release];
				
			}
		} while ((cont) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}


@end

@implementation HrefAttrHandler

//String mLocalname = null;
- (void)OnElementAction:(int)level
{
	char last_char = ' ';
	//mLocalname = null;
	//NSLog(@"%s", __func__);
	
	@try {
		NSMutableData *found = [theParser getThisToken];
		if (found && ([found length] > 0)){
			//last_char = mCharBuffer.charAt(mCharBuffer.length()-1);
			last_char = CharFromNSDataAtIndex(found, [found length]-1);
			
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			NSString *local_name = [theParser.cacheService getLocalName:stripped_href withHandler:self];
			
			//if (mLocalname != null)
			//	encode2safeUrl(mLocalname);
			//else
			//	encode2safeUrl(local_name);
			
			char data = '"';
			[theParser.destStream appendBytes:&data length:1];
			//writeString(FILE_URL_PREFIX);
			[theParser.destStream appendBytes:FILE_URL_PREFIX length:strlen(FILE_URL_PREFIX)];
			//write2Stream();
			//[local_name getCharacters:(unichar*)bytePtr];
			[theParser.destStream appendData:[local_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			[theParser.destStream appendBytes:&data length:1];
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			
			[stripped_href release];
			//[local_name release];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

/*
public void OnFilterAction(String local, String url) {
	int parser = determineParser(url);
	if ((parser == ParserKind.NO_PARSER) && (mLinkType != ParserKind.NO_PARSER)) {
		// We can't determine the type based on extension. we will add it.
		local = local + getExtension(mLinkType);
		parser = mLinkType;
		mLocalname = local;
	}
	
	UrlMatch urlwork = new UrlMatch(local, url);
	
	//if (parser == ParserKind.NO_PARSER)
	//parser = determineParser(urlwork.mOrigName);
	
	if (mLinkType != ParserKind.NO_PARSER) {
		mParsableStack.add(urlwork);
		mRoadStopHash.put(url, local);
	}
	else if ((parser == ParserKind.NO_PARSER) || (parser == ParserKind.HTML_PARSER)) {
		mRoadStack.add(urlwork);
		mRoadHash.put(url, local);
	} 
	else {
		mParsableStack.add(urlwork);
		mRoadStopHash.put(url, local);
	}
	
	//			Log.d(TAG, "Href: parser: " + mLinkType + ", url: "+ url);
}

public void OnPageAction() {
	
}
 */

@end

@implementation SrcAttrHandler

//int mLevel = 0;
- (void)OnElementAction:(int)level
{
	char last_char = ' ';
	currentLevel = level;
	//NSLog(@"%s", __func__);
	
	@try {
		
		NSMutableData *found = [theParser getThisToken];
		
		if (found && ([found length] > 0)) {
			//last_char = mCharBuffer.charAt(mCharBuffer.length()-1);
			last_char = CharFromNSDataAtIndex(found, [found length]-1);
			
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
            //printf("-> href: %s\n", [stripped_href UTF8String]);
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			NSString *local_name = nil;
			if ([theParser querySiteKnowledgeWithKey:@"src" withValue:stripped_href] == YES) {
				local_name = [theParser.cacheService getLocalName:stripped_href withCategory:CACHE_THUMB_NAIL withHandler:self];
			}
			else {
				local_name = [theParser.cacheService getLocalName:stripped_href withHandler:self];
			}
			
			//encode2safeUrl(local_name);
			
			char data = '"';
			[theParser.destStream appendBytes:&data length:1];
			//writeString(FILE_URL_PREFIX);
			[theParser.destStream appendBytes:FILE_URL_PREFIX length:strlen(FILE_URL_PREFIX)];
			//write2Stream();
			//[local_name getCharacters:(unichar*)bytePtr];
			[theParser.destStream appendData:[local_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			[theParser.destStream appendBytes:&data length:1];
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			

			if ([theParser setSiteKnowledge:stripped_href withExtra:local_name forKey:@"src"] == YES) {
				// Move the current embedded object to the first entry, 
				// so that we can identify it later from the embedded file.
				[theParser.cacheService moveTheCurrentEmbeddedObjectToFront];
			}
			[stripped_href release];
			//[local_name release];
			
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

/*
public void OnFilterAction(String local, String url) {	
	UrlMatch urlwork = new UrlMatch(local, url);
	
	mRoadStack.add(urlwork);
	mRoadHash.put(url, local);
	if (mMaxDepth == mLevel) {
		// Only for the parent page, we will save to roadstop.
		mRoadStopHash.put(url, local);
	}
	//			Log.d(TAG, "Src: "+ url);
}

public void OnPageAction() {
	
}
 */

@end

@implementation TypeAttrHandler

- (void)OnElementAction:(int)level
{
	int data=-1;
	int html_type = 0;
	int css_type = 0;
	//NSLog(@"%s", __func__);
	
	@try {
		while ((data = [theParser.htmlStream readFromStream]) != -1) {
			//char c = java.lang.Character.toLowerCase((char) data);
			char c = toLowerCase(data);
			if (c == [HTML_TEXT_TYPE characterAtIndex:html_type]) {
				html_type++;
			} else if (c == [CSS_TEXT_TYPE characterAtIndex:css_type]){
				css_type++;
			} else {
				html_type=0;
				css_type=0;
			}
			
			//mBufferedStream.write(data);
			[theParser.destStream appendBytes:&data length:1];
			
			if (html_type == [HTML_TEXT_TYPE length]) {
				//Log.i(TAG, "mTypeAttrHandler: html type.");
				theParser.linkType = HTML_PARSER;
				break;
			} else if (css_type == [CSS_TEXT_TYPE length]) {
				//Log.i(TAG, "mTypeAttrHandler: css type.");
				theParser.linkType = CSS_PARSER;
				break;
			} else if (c == CHAR_SPACE) {
				break;
			} else if (c == '>') {
				theParser.parserStatus = PARSER_END_ELE;
				break;
			}
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

@end

@implementation StyleImportHandler


- (void)OnElementAction:(int)level
{
	//NSLog(@"%s", __func__);
	
	@try {
		// take out url prefix if this start with it.
		[theParser canConnectThisToken:@"url(" canIgnoreBlank:YES];
		int last_char = [theParser getImportUrlToken];
		if ((last_char != -1) && ([theParser.charBuffer length]>0)){
			//					Log.i(TAG, "Import: "+ mCharBuffer.toString());
			
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			NSString *local_name = [theParser.cacheService getLocalName:stripped_href withHandler:self];
			
			//encode2safeUrl(local_name);
			
			//writeString(FILE_URL_PREFIX);
			[theParser.destStream appendBytes:FILE_URL_PREFIX length:strlen(FILE_URL_PREFIX)];
			//write2Stream();
			[theParser.destStream appendData:[local_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			[stripped_href release];
			//[local_name release];
			
		}
		else if (last_char != -1) {
			//mBufferedStream.write((char)last_char);
			[theParser.destStream appendBytes:&last_char length:1];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
	
}

/*
public void OnFilterAction(String local, String url) {
	UrlMatch urlwork = new UrlMatch(local, url);
	
	mParsableStack.add(urlwork);
	mRoadStopHash.put(url, local);
	
	//			Log.d(TAG, "Style Import: "+ url);
}


public void OnPageAction() {
	
}
 */

@end

@implementation CssUrlHandler

- (void)OnElementAction:(int)level
{
	//NSLog(@"%s", __func__);
	
	@try {
		// take out url prefix if this start with it.
		int last_char = [theParser getImportUrlToken];
		if ((last_char != -1) && ([theParser.charBuffer length]>0)){
			//Log.i(TAG, "Import: "+ href);		
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			NSString *local_name = [theParser.cacheService getLocalName:stripped_href withHandler:self];
			
			//writeString(FILE_URL_PREFIX);
			[theParser.destStream appendBytes:FILE_URL_PREFIX length:strlen(FILE_URL_PREFIX)];
			//write2Stream();
			[theParser.destStream appendData:[local_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			[stripped_href release];
			//[local_name release];
			
		}
		else if (last_char != -1) {
			//mBufferedStream.write((char)last_char);
			[theParser.destStream appendBytes:&last_char length:1];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

/*
public void OnFilterAction(String local, String url) {
	UrlMatch urlwork = new UrlMatch(local, url);
	
	mRoadStack.add(urlwork);
	mRoadHash.put(url, local);
	
	//			Log.d(TAG, "CSS Import: "+ url);
}


public void OnPageAction() {
	
}
 */

@end

@implementation DivStyleAttrHandler

- (void)OnElementAction:(int)level
{
	//NSLog(@"%s", __func__);
	if ([theParser findThisTokenWithQuote:CSS_URL_PREFIX withEndTag:@">"] == NO) {
		// can't find any url, return now
		return;
	}
	
	@try {
		int last_char = [theParser getImportUrlToken];
		if ((last_char != -1) && ([theParser.charBuffer length]>0)){
			//Log.i(TAG, "Import: "+ href);
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			NSString *local_name = [theParser.cacheService getLocalName:stripped_href withHandler:self];
			
			//encode2safeUrl(local_name);
			
			//writeString(FILE_URL_PREFIX);
			[theParser.destStream appendBytes:FILE_URL_PREFIX length:strlen(FILE_URL_PREFIX)];
			//write2Stream();
			[theParser.destStream appendData:[local_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			[stripped_href release];
			//[local_name release];
		}
		else if (last_char != -1) {
			//mBufferedStream.write((char)last_char);
			[theParser.destStream appendBytes:&last_char length:1];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}

/*
public void OnFilterAction(String local, String url) {
	UrlMatch urlwork = new UrlMatch(local, url);
	
	mRoadStack.add(urlwork);
	mRoadHash.put(url, local);
	
	//			Log.d(TAG, "Div Import: "+ url);
}


public void OnPageAction() {
	
}
*/

@end

@implementation ClassAttrHandler

- (void)OnElementAction:(int)level
{
	char last_char = ' ';
	currentLevel = level;
	//NSLog(@"%s", __func__);
	
	@try {
		
		NSMutableData *found = [theParser getThisToken];
		
		if (found && ([found length] > 0)) {
			//last_char = mCharBuffer.charAt(mCharBuffer.length()-1);
			last_char = CharFromNSDataAtIndex(found, [found length]-1);
			
			NSString *stripped_name = [theParser stripUrl:theParser.charBuffer];
			
			char data = '"';
			[theParser.destStream appendBytes:&data length:1];
			
			//[local_name getCharacters:(unichar*)bytePtr];
			[theParser.destStream appendData:[stripped_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			[theParser.destStream appendBytes:&data length:1];
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			[theParser setSiteKnowledge:stripped_name withExtra:nil forKey:@"class"];
			[stripped_name release];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}


@end

@implementation DivEndElementHandler

- (void)OnElementAction:(int)level
{
	theParser.divOpen = NO;
}

@end

@implementation AnchorEndElementHandler

- (void)OnElementAction:(int)level
{
	theParser.anchorOpen = NO;
}

@end

@implementation MetaElementHandler

- (void)OnElementAction:(int)level
{
	// found image tag, need to find src attribute
	if (theParser.parserStatus == PARSER_END_ELE) {
		// There are no attributes, no need to look more.
		return;
	}
	//NSLog(@"%s", __func__);
	canContinue = NO;
	
	@try {
		do {
			NSMutableData *found = [theParser findAttribute];
			
			//Log.d(TAG, "Img: " + mCharBuffer.toString());
			if (found) {
				
				NSString *key = NSDataToString(found);
				ParserHandler *handler = [theParser.attrHandlerMap objectForKey:key];
				//NSLog(@"img attr: %@", key);
				[key release];
				if (handler != nil){
					//Log.d(TAG, "Img: " + mKeyBuffer.toString());		
					//handler.OnElementAction(level);
					[handler OnElementAction:level];
				} 
				
			}
		} while ((canContinue == YES) && (theParser.parserStatus != PARSER_END_ELE));
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}


@end


@implementation MetaNameAttrHandler


- (void)OnElementAction:(int)level
{
	char last_char = ' ';
	currentLevel = level;
	//NSLog(@"%s", __func__);
	
	@try {
		
		NSMutableData *found = [theParser getThisToken];
		
		if (found && ([found length] > 0)) {
			//last_char = mCharBuffer.charAt(mCharBuffer.length()-1);
			last_char = CharFromNSDataAtIndex(found, [found length]-1);
			
			NSString *stripped_name = [theParser stripUrl:theParser.charBuffer];
			
			char data = '"';
			[theParser.destStream appendBytes:&data length:1];
			
			//[local_name getCharacters:(unichar*)bytePtr];
			[theParser.destStream appendData:[stripped_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			[theParser.destStream appendBytes:&data length:1];
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			if ([theParser setSiteKnowledge:stripped_name withExtra:nil forKey:@"name"] == YES) {
				canContinue = YES;
			}
			[stripped_name release];
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}


@end


@implementation MetaContentAttrHandler

- (void)OnElementAction:(int)level
{
	char last_char = ' ';
	currentLevel = level;
	//NSLog(@"%s", __func__);
	
	@try {
		
		NSMutableData *found = [theParser getThisToken];
		
		if (found && ([found length] > 0)) {
			//last_char = mCharBuffer.charAt(mCharBuffer.length()-1);
			last_char = CharFromNSDataAtIndex(found, [found length]-1);
			
			NSString *stripped_href = [theParser stripUrl:theParser.charBuffer];
			
			//if (stripped_href.startsWith(HTTP_PREFIX) == false)
			if ([stripped_href hasPrefix:HTTP_PREFIX] == NO) {	
				//stripped_href = combineUrl(theParser.hostUrl, stripped_href);
				stripped_href = relativeStringToURL(stripped_href, theParser.baseURL);
				[stripped_href retain];
			}
			
			NSString *local_name = nil;
			if ([theParser querySiteKnowledgeWithKey:@"content"] == YES) {
				local_name = [theParser.cacheService getLocalName:stripped_href withCategory:CACHE_THUMB_NAIL withHandler:self];
			}
			else {
				local_name = [theParser.cacheService getLocalName:stripped_href withHandler:self];
			}
			
			//encode2safeUrl(local_name);
			
			char data = '"';
			[theParser.destStream appendBytes:&data length:1];
			//writeString(FILE_URL_PREFIX);
			[theParser.destStream appendBytes:FILE_URL_PREFIX length:strlen(FILE_URL_PREFIX)];
			//write2Stream();
			//[local_name getCharacters:(unichar*)bytePtr];
			[theParser.destStream appendData:[local_name dataUsingEncoding:NSUTF8StringEncoding]];
			//mBufferedStream.write((char)'"');
			[theParser.destStream appendBytes:&data length:1];
			//mBufferedStream.write(last_char);
			[theParser.destStream appendBytes:&last_char length:1];
			
			
			if ([theParser setSiteKnowledge:stripped_href withExtra:local_name forKey:@"content"] == YES) {
				// Move the current embedded object to the first entry, 
				// so that we can identify it later from the embedded file.
				[theParser.cacheService moveTheCurrentEmbeddedObjectToFront];
			}
			[stripped_href release];
			//[local_name release];
			
		}
	}
	@catch (NSException *e) {
		NSLog(@"Exception at: %s, %@", __func__, [e reason]);
	}
	
}


@end


