//
//  SocketHelper.h
//  NYTReader
//
//  Created by Jae Han on 9/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include "MReader_Defs.h"
#import <UIKit/UIKit.h>

#define MAX_HEADER_LINE		1024
#define MAX_RESPONSE_DATA	4096

typedef enum {RESPONSE_NONE, RESPONSE_START, RESPONSE_UNSUPPORTED, RESPONSE_OK, RESPONSE_REDIRECT, RESPONSE_MOVE_PERMANENTLY,RESPONSE_CHUNKED, RESPONSE_NOT_FOUND} response_parser_stat_t;
typedef enum {SEARCH_PROTOCOL_TYPE, SEARCH_GET_RESULT, BEGIN_NEW_LINE, SEARCH_FIELD, SEARCH_VALUE, SKIP_TO_NEXT_LINE, BODY_FOUND} response_parser_mode_t;
typedef enum {CHUNKED_DATA, CHUNKED_CR, CHUNKED_LF, CHUNKED_NUM, CHUNKED_LEN_DETECTED, CHUNKED_CR2, CHUNKED_LF2} chunked_parser_t;

@class HeaderFieldValue;

@interface DnsHelper : NSObject 
{
	NSMutableDictionary		*dnsCache;
	//NSNetService *netService;
}

- (struct sockaddr*)getHostAddress:(NSString*)host;

@end


@interface SocketHelper : NSObject {
	@private
	int						sockfd;
	NSString				*host_name;
	//struct hostent			*hp;
	NSMutableData			*requestHeader;
	NSMutableData			*responseHeaderHolder;
	NSMutableData			*responseBody;
	NSMutableData			*tempHeader;
	response_parser_stat_t	responseStatus;
	NSDictionary			*responseFields;
	response_parser_mode_t	parserMode;
	int						currentIndex, markIndex, beginIndex;
	HeaderFieldValue		*currentValue;
	int						contentLength;
	BOOL					keepAlive;
	int						chunkedBodyLength;
	BOOL					foundChunkPrefix;
	BOOL					isAlive;
	int						redirectionCount;
	chunked_parser_t		chunkedParserMode;
	int						chunkedLenIndex;
	DnsHelper				*dnsHelper;
	BOOL					shouldSetCookie;
	NSHTTPCookieStorage		*cookieStorage;
	
	unsigned char			headerBuffer[MAX_HEADER_LINE];
	unsigned char			responseBuffer[MAX_RESPONSE_DATA];
	char					intLenBuffer[10];
	NSArray					*headerFieldArray;
	NSArray					*headerFieldValueArray;
}

- (BOOL)createSocketWithHostName:(NSString*)host keepAlive:(BOOL)alive;
- (BOOL)addRequestHeader:(NSString*)header withValue:(NSString*)value;
- (void)finishRequestHeader;
- (NSData*)sendRequest;
- (BOOL)createRequestWithURL:(NSURL*)url;
- (BOOL)processResponse:(unsigned char*)data withLength:(int)length;
- (NSData*)getResponseData;
- (NSData*)redirectRequestToURL:(NSURL*) url useConnection:(BOOL)connectionAlive;
- (void)close;
- (NSData*)getResponseHeader;
- (BOOL)processChunkedBody:(char*)data length:(int)len;
- (BOOL)isSocketActive;
- (NSData*)sendRequest:(MReaderParserType)type;
- (NSString*)getResponseHeaderValue:(NSString*)field;
- (void)setCookie:(NSString*)cookie;
- (NSString*)getCookie:(NSURL*)url;
@end
