//
//  HTTPUrlHelper.h
//  NYTReader
//
//  Created by Jae Han on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MReader_Defs.h"

@class XMLReader;
@class WebCacheService;
@class CacheEntry;
@class EmbeddedObjects;
@class HTTPConnection;
@class SocketHelper;
@class NetworkService;

@interface HTTPUrlHelper : NSObject {
	//NSMutableData	*receivedData;
	//XMLReader		*xmlParser;
	MReaderParserType	parserType;
	id					parserDelegate;
	CacheEntry			*theCacheEntry;
	
	@private
	NSHTTPURLResponse	*theResponse;
	//NSMutableArray		*connectionArray;
	WebCacheService		*cacheService;
	NSIndexPath			*theCurrentFeedIndexPath;
	NSMutableURLRequest *theRequest;
	HTTPConnection		*theConnection;
	//SocketHelper		*socket;
	BOOL				isCached;
	BOOL				useiPhoneSDK;
	NetworkService		*networkService;
	NSURL				*baseURL;
	NSString			*cacheFileName;
	BOOL				shouldIgnoreCache;
	BOOL				shouldNotifyReloadXML;
	BOOL				done;
	BOOL				isFailed;
	BOOL				isLocalRequest;
	NSData				*cachedData;
}

@property (nonatomic, retain) NSData *cachedData;
@property (nonatomic) BOOL isLocalRequest;

- (BOOL)parseReceivedData:(NSData*)data withIndex:(NSIndexPath*)indexPath fromCache:(BOOL)usingCache;
- (BOOL)requestWithURL:(NSURL*)url fileToSave:(NSString*)file parserKind:(MReaderParserType)type feedIndex:(NSIndexPath*)indexPath shouldWait:(BOOL)wait;
- (BOOL)requestWithURLUseCache:(NSURL*)url delegate:(id)delegate parserKind:(MReaderParserType)type feedIndex:(NSIndexPath*)indexPath shouldWait:(BOOL)wait;
- (void)saveToFile:(NSString*)fileName withData:(NSData*)data;
- (BOOL)constructResponseWithHeader:(NSData**)header withBody:(NSData**)body toReleaseHeader:(BOOL*)release;
- (void)finishConnection;
- (NSString*)getCachedName;
- (void)ignoreCache:(BOOL)ignore;
- (void)notifyReloadXML:(BOOL)notify;
- (NSData*)getResponseHeader;

//- (NSInteger)findIndexWithConnection:(NSURLConnection*)connection;
//@property (nonatomic, retain) NSMutableData* receivedData;
/*
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
*/
@end
