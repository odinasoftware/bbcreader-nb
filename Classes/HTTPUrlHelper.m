//
//  HTTPUrlHelper.m
//  NYTReader
//
//  Created by Jae Han on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import "MReader_Defs.h"
#import "HTTPUrlHelper.h"
#import "XMLReader.h"
#import "HTTPConnection.h"
#import "CacheEntry.h"
#import "WebCacheService.h"
#import "HTMLParser.h"
#import "ArticleStorage.h"
#import	"SocketHelper.h"
#import "Configuration.h"
#import "NetworkService.h"
#import "HTTPUrlHelper.h"

#define REPEAT_COUNT	2
#define HTTP_OK			"HTTP/1.1 200 OK\r\n"

/*
HTTP/1.1 200 OK
ETag: "260c-457d786faa140"
Accept-Ranges: bytes
Content-Length: 9740
Last-Modified: Sat, 27 Sep 2008 02:38:21 GMT
Server: Apache
Content-Type: image/jpeg
Cache-Control: max-age=7200
Expires: Sat, 27 Sep 2008 18:21:16 GMT
Date: Sat, 27 Sep 2008 16:21:16 GMT
Connection: keep-alive
 */

cache_category_t getCategory(MReaderParserType type) 
{
	if (type == MREADER_XML_PARSER) 
		return CACHE_FEED;
	else if (type == MREADER_HTML_PARSER)
		return CACHE_HTML;
	
	return CACHE_NONE;
}

@implementation HTTPUrlHelper

//@synthesize receivedData;

-(id) init {
	if ((self = [super init])) {
		parserDelegate = nil;
		theCacheEntry = nil;
		//connectionArray = [[NSMutableArray alloc] init];
		cacheService = [WebCacheService sharedWebCacheServiceInstance];
		theConnection =  nil; 
		isCached = NO;
		networkService = [NetworkService sharedNetworkServiceInstance];
		cacheFileName = nil;
		shouldIgnoreCache = NO;
		shouldNotifyReloadXML = YES;
		done = NO;
	}
	return self;
}

-(BOOL) requestWithURL:(NSURL*) url fileToSave:(NSString*)file parserKind:(MReaderParserType)type feedIndex:(NSIndexPath*)indexPath shouldWait:(BOOL)wait
{
	BOOL isDataAvailable = YES;

	useiPhoneSDK = NO;
	
	if ([cacheService doesCacheExist:(NSString*)file]) {
		isCached = YES;
		parserType = type;
		return YES;
	}
	
	
	isCached = NO;
	parserType = type;
		
	if (networkService.offlineMode == YES) {
		// don't look at Internet in offline mode
		return NO;
	}
	

	theRequest = [[NSMutableURLRequest alloc] initWithURL:url
											  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										  timeoutInterval:60.0];
	//[theRequest addValue:@"CFNetwork/330" forHTTPHeaderField:@"User-Agent"];
	//[theRequest addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
	[theRequest addValue:@"Mozilla/5.0 (iPhone; BBCReader; CPU iPhone OS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20" forHTTPHeaderField:@"User-Agent"];
	[theRequest addValue:@"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" forHTTPHeaderField:@"Accept"];
	[theRequest	addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
	
	useiPhoneSDK = YES;
	TRACE("%s, use NSURLRequest.\n", __func__);

	theConnection = [[HTTPConnection alloc] initWithRequest:theRequest delegate:self];
	
	if (theConnection) {
		theConnection.indexForFeed = indexPath;
		theConnection.localFile = file;
		//[connectionArray insertObject:(id)theConnection	atIndex:indexPath.row];
		TRACE("%s, add connection: %x to index: (%d, %d), file: %s\n", __func__, (id)theConnection, indexPath.section, indexPath.row, [file UTF8String]);
		[theConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
		[theConnection start];
	}
	
	return isDataAvailable;
}

- (void)ignoreCache:(BOOL)ignore 
{
	shouldIgnoreCache = ignore;
}

- (void)notifyReloadXML:(BOOL)notify
{
	shouldNotifyReloadXML = notify;
}

/*
 * requestWithUrlUseCache: 
 *	before getting the URL, it will check cache to see if there is an entry for that.
 *	if it is, it will getting from the cache. 
 *	the cache file will be used later after the URL is downloaded.
 *	
 *	After the page is downloaded,
 *		1. parse with the data -> use XML or HTML parser. 
 *		2. the cache file will be used to store the parsed data. 
 *			- In case of XML, will not change the content of data
 *			- For HTML, it will parse and store with local file.
 */


//GET /iphone/ HTTP/1.1
//User-Agent: Mozilla/5.0 (iPhone Simulator; U; CPU iPhone OS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20
//Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
//Accept-Language: en-us
//Accept-Encoding: gzip, deflate
//Connection: keep-alive
//Host: www.apple.com

 -(BOOL) requestWithURLUseCache:(NSURL*) url delegate:(id)delegate parserKind:(MReaderParserType)type feedIndex:(NSIndexPath*)indexPath shouldWait:(BOOL)wait
{
	
	BOOL isDataAvailable = YES;
	BOOL updateDate = NO;
	// TODO: need to modify
	parserType = type;
	parserDelegate = delegate;
	
	isCached = NO;
	BOOL cont = NO;
	
	useiPhoneSDK = NO;
	theCurrentFeedIndexPath = indexPath;
	

	theCacheEntry = [cacheService getCachedFileName:url withCategory:getCategory(type) isAvailable:&isCached];

	if (getCategory(type) == CACHE_FEED) {
		cacheFileName = theCacheEntry.cacheFile;
	}
	
	if (type == HTML_PARSER) {
		baseURL = url;
		//[(HTMLParser*)delegate setBaseUrl:url];
	}
	

		if (networkService.offlineMode == YES && isCached == NO && theCacheEntry.cacheFile != nil) {
			// In offline moe, we will use from cache even it is stale.
			isCached = YES;
			NSLog(@"%s, offline mode, will use cache.", __func__);
		}
		
		if (shouldIgnoreCache == YES || isCached == NO) {
			// add custom header
			isCached = NO;
			if (networkService.offlineMode == YES) {
				// don't look at Internet in offline mode
				[theCacheEntry release];
				return NO;
			}
			
			
			theRequest = [[NSMutableURLRequest alloc] initWithURL:url
													  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
												  timeoutInterval:60.0];
			//[theRequest addValue:@"CFNetwork/330" forHTTPHeaderField:@"User-Agent"];
			//[theRequest addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
			[theRequest addValue:@"Mozilla/5.0 (iPhone; BBCReader; CPU iPhone OS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20" forHTTPHeaderField:@"User-Agent"];
			[theRequest addValue:@"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" forHTTPHeaderField:@"Accept"];
			[theRequest	addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
			
			useiPhoneSDK = YES;
			TRACE("%s, use NSURLRequest.\n", __func__);
			
			theConnection = [[HTTPConnection alloc] initWithRequest:theRequest delegate:self startImmediately:NO];
			if (theConnection) {
				theConnection.indexForFeed = indexPath;
				//[connectionArray insertObject:(id)theConnection	atIndex:indexPath.row];
				TRACE("%s, add connection: %x to section: %d, row: %d\n", __func__, (id)theConnection, indexPath.section, indexPath.row);
				[theConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
				[theConnection start];
				do {
					[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
				} while (!done);
			}
			
			
			
			cont = NO;
			
			if ((getCategory(type) == CACHE_FEED) && updateDate == YES){
				Configuration *config = [Configuration sharedConfigurationInstance];
				
				config.lastUpdatedDate = [NSDate date]; //time(nil);
				[config saveSettings];
			}
		}
		
	
	return isDataAvailable;
}

- (NSString*)getCachedName
{
	return cacheFileName;
}

- (BOOL)parseReceivedData:(NSData*)data withIndex:(NSIndexPath*)indexPath fromCache:(BOOL)usingCache
{
	NSError *parseError = nil;
	BOOL success = YES;
	
	TRACE("%s, before parsing.\n", __func__);
	// Read from the file
	switch (parserType) {
		case MREADER_XML_PARSER:
			@synchronized(cacheService) {
				[(XMLReader*)parserDelegate parseXMLData:data parseError:&parseError withIndex:indexPath shouldNotify:shouldNotifyReloadXML];
			}
			break;
		case MREADER_HTML_PARSER:
			@synchronized(cacheService) {
				[parserDelegate setBaseUrl:baseURL];
				if (usingCache == NO) {
					
					[cacheService prepareEmbeddedObjectsStorage:theCacheEntry];
					[(HTMLParser*)parserDelegate parse:data withCache:cacheService withCacheEntry:theCacheEntry atIndexPath:indexPath];
					[cacheService saveEmbeddedObjectsToStorage];
				}
				else {
					// post-processing when the content coming from cache.
					[cacheService postProcessing:theCacheEntry atIndex:indexPath];
				}
			}
			break;
		case MREADER_FILE_TYPE:
			// don't need to parse
			break;
		default:
			NSLog(@"Unknown parser type: %d", parserType);
	}
	
	if (parseError != nil) {
		NSLog(@"%s: RSS parse error, %@", __func__, parseError);
		success = NO;
		//[parseError release];
	}	
	TRACE("%s, end parsing.\n", __func__);
	
	return success;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"%s, %@", __func__, error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	/* This method is called when the server has determined that it has
	 enough information to create the NSURLResponse. It can be called
	 multiple times, for example in the case of a redirect, so each time
	 we reset the data. */
	
    [theConnection.receivedData setLength:0];
	
	//theResponse = (NSHTTPURLResponse*)response;
	/* Try to retrieve last modified date from HTTP header. If found, format  
	 date so it matches format of cached image file modification date. */
	
	if ([response isKindOfClass:[NSHTTPURLResponse self]]) {
		theResponse = (NSHTTPURLResponse*) response;
		[theResponse retain];
		/*
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		NSString *modified = [headers objectForKey:@"Last-Modified"];
		if (modified) {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
			self.lastModified = [dateFormatter dateFromString:modified];
			[dateFormatter release];
		}
		else {
			// default if last modified date doesn't exist (not an error) 
			self.lastModified = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
		}
	*/
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	TRACE("%s, %d\n", __func__, [data length]);
	if (theConnection.receivedData == nil) {
		theConnection.receivedData = [[NSMutableData alloc] init];
	}
	[theConnection.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{ 
	BOOL parserStatus = YES;
	//HTTPConnection* theConnection = (HTTPConnection*)connection;
	
	// do something with the data 
	// receivedData is declared as a method instance elsewhere 
	TRACE("Succeeded! %p, Received %d bytes of data\n", connection, [theConnection.receivedData length]); 
	// release the connection, and the data object 

	if ([theConnection.receivedData length] > 0) {
		//NSInteger index = theConnection.indexForFeed.row; // better way. [self findIndexWithConnection:connection];
		//if (index < 0) {
		//	NSLog(@"%s, feed index error: %d", __func__, index);
		//	return;
		//}
		TRACE("%s, start parsing with: connection: %x\n", __func__, (id) connection);
		parserStatus = [self parseReceivedData:theConnection.receivedData withIndex:theConnection.indexForFeed fromCache:NO];
		
		// save to cache
		//[self saveToFile:localFile withData:theConnection.receivedData];
		switch (parserType) {
			case MREADER_XML_PARSER:
				// XML does not change the content, so we can just save it.
				if (parserStatus == YES) {
					[cacheService saveToCache:theCacheEntry withData:theConnection.receivedData];
					[cacheService saveResponseHeader:[self getResponseHeader] withLocalFile:theCacheEntry.cacheFile];
				}
				else {
					NSLog(@"%s, parser failed.", __func__);
				}
				
				[theCacheEntry release];
				break;
			case MREADER_FILE_TYPE:
				[self saveToFile:theConnection.localFile withData:theConnection.receivedData];
				[cacheService saveResponseHeader:[self getResponseHeader] withLocalFile:theConnection.localFile];
				// TODO: tell tableview we have a picture
				// Before setting we will have to set the image file to WebLink.
				[ArticleStorage setImageLink:theConnection.localFile atIndexPath:theConnection.indexForFeed];
				[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:nil	waitUntilDone:YES];
				break;
			case MREADER_HTML_PARSER:
				[cacheService flushCacheEntry:theCacheEntry];
				[cacheService saveResponseHeader:[self getResponseHeader] withLocalFile:theCacheEntry.cacheFile];
				[theCacheEntry release];
				break;
			default:
				NSLog(@"Unknown parser type: %d", parserType);
		}
	}
	//[theConnection.receivedData release]; should be released in SocketHelper
	//[theRequest release];
	//[connection release]; 
	
	//return parserStatus;
	done = YES;
} 

- (BOOL)constructResponseWithHeader:(NSData**)header withBody:(NSData**)body toReleaseHeader:(BOOL*)release
{
	*release = NO;
	
	if (useiPhoneSDK == NO || theConnection == nil || 
		(useiPhoneSDK == NO && isCached == NO)) {
		NSLog(@"%s, invalid connection.", __func__);
		*header = nil;
		*body = nil;
		return NO;
	}
	
	if (isCached == NO) {
		//[theConnection.receivedData retain]; // will be released by localServer
		[self connectionDidFinishLoading:theConnection];
		TRACE(">>>>> %s, not cached.\n", __func__);
		*header = [self getResponseHeader];
		if (parserType == MREADER_HTML_PARSER) {
			//[theConnection.receivedData retain];
			[((HTMLParser*)parserDelegate).destStream retain]; // will be released by localServer
			*body = ((HTMLParser*)parserDelegate).destStream;
		}
		else {
			*body = theConnection.receivedData;
		}
		
	}
	else {
		TRACE(">>>> %s, cached.\n", __func__);
		NSString *name = [theCacheEntry.cacheFile stringByAppendingString:@".req"];
		//NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:name];
		*header = [cacheService readFromFile:name]; //[handle readDataToEndOfFile];
		*release = YES;

		*body = theConnection.receivedData;
		if (*header == nil || *body == nil) {
			NSLog(@">>>>> %s: error in data. %p, %p", __func__, *header, *body);
		}
	}
	
	return YES;
}

- (NSData*)getResponseHeader
{
	NSData *response = nil;
	
	NSDictionary *responseDict = [theResponse allHeaderFields];
	
	NSEnumerator *enumerator = [responseDict keyEnumerator];
	
	id key;
	NSString *field;
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:200];
	NSString *line;
	[buffer setLength:0];
	[buffer appendBytes:HTTP_OK length:strlen(HTTP_OK)];
	while (key = [enumerator nextObject]) {
		if ([(NSString*)key caseInsensitiveCompare:@"Connection"] == NSOrderedSame) {
			line = [[NSString alloc] initWithString:@"Connection: close\r\n"];
			[buffer appendBytes:[line UTF8String] length:[line length]];
			[line release];
			continue;
		}
		else if ([(NSString*)key caseInsensitiveCompare:@"Keep-Alive"] == NSOrderedSame) {
			continue;
		}
		
		field = [responseDict objectForKey:key];
		line = [[NSString alloc] initWithFormat:@"%@: %@\r\n", (NSString*)key, field];
		[buffer appendBytes:[line UTF8String] length:[line length]];
		[line release];
	}
	[buffer appendBytes:"\r\n" length:2];
	response = buffer;	
	[theResponse release];
	
	return response;
}

- (void)finishConnection
{
	//if (isCached == NO) {
		//[self connectionDidFinishLoading:theConnection];
	//}
	//else {
	if (isCached == YES) {
		[self parseReceivedData:theConnection.receivedData withIndex:nil fromCache:YES];
		if (parserType == MREADER_XML_PARSER || parserType == MREADER_HTML_PARSER) {
			[theCacheEntry release];
		}
	}
	
}

- (void)saveToFile:(NSString*)fileName withData:(NSData*)data
{
	if (fileName == nil || data == nil || [data length] == 0) {
		NSLog(@"%s, invalid file detected.", __func__);
		return;
	}
	
	NSFileManager* fileManager = [NSFileManager defaultManager];
	[fileManager createFileAtPath:fileName contents:data attributes:nil];
}

- (void)dealloc {
	//[theCacheEntry release];
	[theRequest release];
	[theConnection release];
	[super dealloc];
}


@end
