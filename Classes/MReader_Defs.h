/*
 *  MReader_Defs.h
 *  NYTReader
 *
 *  Created by Jae Han on 7/29/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

typedef enum {MREADER_XML_PARSER, MREADER_HTML_PARSER, MREADER_FILE_TYPE} MReaderParserType;
typedef enum {CACHE_NONE, CACHE_THUMB_NAIL, CACHE_HTML, CACHE_FEED} cache_category_t;

#define CHECK_LATER 1

#define MREADER_TITLE_TAG		1
#define MREADER_IMG_TAG			2
#define MREADER_LOGO_TAG		3
#define MREADER_DESCRIPTION_TAG	4

#define TABLE_WIDTH			320
#define TABLE_HEIGHT		347

#define RECT_START_MARGIN	10.0
#define IMG_MARGIN			5.0
#define IMG_RECT_X			5.0
#define IMG_RECT_Y			8.0
#define IMG_RECT_WIDTH		80.0 //100
#define IMG_RECT_HEIGHT		65.6 //82.0

#define TITLE_RECT_X		IMG_RECT_WIDTH + 10.0
#define TITLE_RECT_Y		0.0
#define TITLE_RECT_WIDTH	180	
#define TITLE_RECT_HEIGHT	40

#define DESC_RECT_X			IMG_RECT_WIDTH + 10.0
#define DESC_RECT_Y			37
#define DESC_RECT_WIDTH		TITLE_RECT_WIDTH + 35
#define DESC_RECT_HEIGHT	47

#ifdef _DEBUG
#define TRACE(fmt, args...) printf(fmt, ## args)
#else
#define TRACE(fmt, args...)
#endif

#define	TRACE_HERE		TRACE("%s\n", __func__)

extern NSString *getActualPath(NSString* sourcePath);
extern int OPEN(NSString* name, int flag);
