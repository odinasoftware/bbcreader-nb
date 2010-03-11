/*
 *  Parser_Defs.h
 *  NYTReader
 *
 *  Created by Jae Han on 7/30/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

extern char START_TAG;
extern char END_TAG;
extern char END_SLASH;
extern char CHAR_SPACE;
extern char CHAR_ASSIGN;
extern char CHAR_NEWLINE;
extern char CHAR_LINEFEED;
extern char CHAR_TAB;
extern char CHAR_EXCL;
extern char CHAR_END_PARAN;
extern char CHAR_SEMI_COLON;

extern NSString* COMMENT_POSTFIX;
extern NSString* END_OF_COMMENT;
extern NSString* HTTP_PREFIX;
extern NSString* HTML_EXT;
extern NSString* SPACE_ENCODE;
extern NSString* SCRIPT_END_TAG;
extern NSString* STYLE_END_TAG;
extern NSString* TYPE_ATTR;
extern NSString* END_LI_TOKEN;

extern NSString* IMPORT_STYLE_TOKEN;
extern NSString* CSS_URL_STYLE_TOKEN;
extern NSString* CSS_URL_PREFIX;
extern NSString* TITLE_ELE;
extern NSString* IMG_ELE;
extern NSString* TD_ELE;
extern NSString* SCRIPT_ELE;
extern NSString* LINK_ELE;
extern NSString* INPUT_ELE;
extern NSString* STYLE_ELE;
extern NSString* DIV_ELE;
extern NSString* IFRAME_ELE;
extern NSString* ANCHOR_ELE;
extern NSString* LI_ELE;
extern NSString* FORM_ELE;
extern NSString* SPAN_ELE;

extern NSString *SRC_TYPE;
extern NSString *BACKGROUND_TYPE;
extern NSString *HREF_TYPE;
extern NSString *ACTION_TYPE;

extern NSString *HTML_TEXT_TYPE;
extern NSString *CSS_TEXT_TYPE;

extern char* FILE_URL_PREFIX;

// Extern function definitions
extern unichar toLowerCase(unichar c);
extern NSString* NSDataToString(NSData* x);
extern char CharFromNSDataAtIndex(NSData *x, int i);
