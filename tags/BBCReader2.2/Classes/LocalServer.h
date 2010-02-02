//
//  LocalServer.h
//  NYTReader
//
//  Created by Jae Han on 9/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LOCAL_BUFFER_SIZE	1024

typedef enum {SEARCH_METHOD, SEARCH_REQUEST, BEGIN_NEW_LINE, SEARCH_REQUEST_FIELD, SEARCH_REQUEST_VALUE, SKIP_TO_NEXT_LINE} request_parser_mode_t;

@class NetworkService;
@class WebCacheService;
@class LocalServerManager;
@class HTTPUrlHelper;

@interface LocalServer : NSThread {
	BOOL	stopIt;
	NSString *localRequest;
	BOOL	isRequestValid;
	
	@private
	//int signal_pipe[2];
	int currentReadPtr;
	int currentWritePtr;
	int markIndex;
	request_parser_mode_t parserMode;
	NetworkService *theNetworkService;
	WebCacheService *theCacheService;
	NSData	*theNotFoundBody;
	NSData	*theNotFoundResHeader;
	BOOL needToDisplaySplash;
	int connectedFD;
	LocalServerManager *serverManager;
	unsigned char local_buffer[LOCAL_BUFFER_SIZE];
}

@property (assign) BOOL stopIt;
@property (assign) BOOL isRequestValid;
@property (nonatomic, retain) NSString *localRequest;

- (id)initWithManager:(LocalServerManager*)manager connFD:(int)fd;
//- (void)startLocalServer;
- (void)stopLocalServer;
- (BOOL)readFromConnection:(int)connfd;
- (int)processRequestHeader:(int)count;
- (HTTPUrlHelper*)getResponseWithOrigUrl:(NSString*)orig_url withHeader:(NSData**)header withBody:(NSData**)body toReleaseHeader:(BOOL*)release;
- (HTTPUrlHelper*)getResponseWithFile:(NSString*)file withHeader:(NSData**)header withBody:(NSData**)body toReleaseHeader:(BOOL*)release;
- (void)resetConnection;
- (void)initSignalHandler;
- (HTTPUrlHelper*)requestWithURLUseCache:(NSString*)orig_url responseHeader:(NSData**)header responseBody:(NSData**)body toReleaseHeader:(BOOL*)release;
- (HTTPUrlHelper*)requestWithURL:(NSString*)orig_url fileToSave:(NSString*)file responseHeader:(NSData**)header responseBody:(NSData**)body toReleaseHeader:(BOOL*)release;

@end
