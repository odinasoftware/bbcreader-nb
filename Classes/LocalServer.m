//
//  LocalServer.m
//  NYTReader
//
//  Created by Jae Han on 9/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
//#define _DEBUG 
#include <sys/socket.h>
#include <sys/select.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <fcntl.h>

#import "LocalServer.h"
#import "NetworkService.h"
#import "WebCacheService.h"
#import "LocalServerManager.h"
#import "HTTPUrlHelper.h"

#define STOP_LOCAL_SERVER	"stop"
#define CARRIAGE_RETURN		0x0d
#define LINE_FEED			0x0a
#define CHUNKED_SIZE		1500

static NSTimeInterval LOCAL_SERVER_CONNECTION_TIMEOUT = 5.0;

static const char *notFoundResponse = "HTTP/1.1 404 Not Found\r\nContent-length: 56\r\nConnection: close\r\n\r\n";
							     //          11        21        31        41        51 
								 //012345678901234567890123456789012345678901234567890123456789
//static const char *notFoundBody = "<script language='JavaScript'> /*Not Found*/ </script>\r\n";
static const char *notFoundBody = "Body not found. Should stop here. Please!!!           \r\n";
BOOL localServerStarted = NO;
int broken_pipe_count = 0;

//extern pthread_mutex_t network_mutex;

void sigpipe_handler(int sig)
{
	//NSLog(@"%s", __func__);
	broken_pipe_count++;
}

@implementation LocalServer

@synthesize stopIt;
@synthesize isRequestValid;
@synthesize localRequest;

- (id)init
{
	if ((self = [super init])) {
		currentReadPtr = currentWritePtr = markIndex = 0;
		localRequest = nil;
		isRequestValid = NO;
		theNetworkService = [NetworkService sharedNetworkServiceInstance];
		theCacheService = [WebCacheService sharedWebCacheServiceInstance];
		theNotFoundBody = [[NSData alloc] initWithBytes:notFoundBody length:strlen(notFoundBody)];
		theNotFoundResHeader = [[NSData alloc] initWithBytes:notFoundResponse length:strlen(notFoundResponse)];
		[self initSignalHandler];
		needToDisplaySplash = YES;
	}
	
	return self;
}

- (id)initWithManager:(LocalServerManager*)manager connFD:(int)fd
{
	if ((self = [super init])) {
		currentReadPtr = currentWritePtr = markIndex = 0;
		localRequest = nil;
		isRequestValid = NO;
		theNetworkService = [NetworkService sharedNetworkServiceInstance];
		theCacheService = [WebCacheService sharedWebCacheServiceInstance];
		theNotFoundBody = [[NSData alloc] initWithBytes:notFoundBody length:strlen(notFoundBody)];
		theNotFoundResHeader = [[NSData alloc] initWithBytes:notFoundResponse length:strlen(notFoundResponse)];
		[self initSignalHandler];
		needToDisplaySplash = YES;
		connectedFD = fd;
		serverManager = manager;
	}
	
	return self;
}

- (void)initSignalHandler
{
	struct sigaction sa;
	
	sa.sa_flags = 0;
	
	sigemptyset(&sa.sa_mask);
	sigaddset(&sa.sa_mask, SIGPIPE);
	
	sa.sa_handler = sigpipe_handler;
	sigaction(SIGPIPE, &sa, nil);
}

- (void)stopLocalServer
{
	localServerStarted = NO;
	//if (write(signal_pipe[1], STOP_LOCAL_SERVER, strlen(STOP_LOCAL_SERVER)) < 0) {
	//	NSLog(@"%s: %s", __func__, strerror(errno));
	//}
}

- (int)processRequestHeader:(int)count 
{
	do {
		switch (parserMode) {
			case SEARCH_METHOD:
				markIndex = 0;
			
				if (local_buffer[currentReadPtr] == ' ') {
					NSString *method = [[NSString alloc] initWithBytes:&local_buffer[markIndex] length:currentReadPtr-markIndex encoding:NSUTF8StringEncoding];
					if ([method compare:@"GET"] == NSOrderedSame) {
						currentReadPtr++;
						markIndex = currentReadPtr;
						parserMode = SEARCH_REQUEST;
						continue;
					}
					else {
						NSLog(@"Unsupported method found: %@", method);
						return -1;
					}
					[method release];
				}
				currentReadPtr++;
				break;
			case SEARCH_REQUEST:
				if (local_buffer[currentReadPtr] == ' ') {
					localRequest = [[NSString alloc] initWithBytes:&local_buffer[markIndex] length:currentReadPtr-markIndex encoding:NSUTF8StringEncoding];
					currentReadPtr++;
					markIndex = currentReadPtr;
					parserMode = SEARCH_REQUEST_FIELD;
					TRACE(">>>>>> found request: %s\n", [localRequest UTF8String]);
					isRequestValid = YES;
					continue;
				}
				currentReadPtr++;
				break;
			case BEGIN_NEW_LINE:
				markIndex = currentReadPtr;
				if (((currentReadPtr + 2) < currentWritePtr) && 
					((local_buffer[currentReadPtr] == CARRIAGE_RETURN) && (local_buffer[currentReadPtr+1] == LINE_FEED))) {
					currentReadPtr += 2;
					return 0;
				}
				else {
					parserMode = SEARCH_REQUEST_FIELD;
				}
				break;
			case SEARCH_REQUEST_FIELD:
				if (local_buffer[currentReadPtr] == ' ') {
					NSString *field = [[NSString alloc] initWithBytes:&local_buffer[markIndex] length:currentReadPtr-markIndex encoding:NSUTF8StringEncoding];
					if ([field compare:@"Host:"] == NSOrderedSame) {
						currentReadPtr++;
						markIndex = currentReadPtr;
						parserMode = SEARCH_REQUEST_VALUE;
						[field release];
						continue;
					}
					else {
						parserMode = SKIP_TO_NEXT_LINE;
					}
					[field release];
				}
				currentReadPtr++;
				break;
			case SEARCH_REQUEST_VALUE:
				if (local_buffer[currentReadPtr] == ' ') {
					NSString *value = [[NSString alloc] initWithBytes:&local_buffer[markIndex] length:currentReadPtr-markIndex encoding:NSUTF8StringEncoding];
					//TRACE(">>>>>>> %s\n", [value UTF8String]);
					if ([value compare:@"localhost"] == NSOrderedSame) {
						currentReadPtr++;
						markIndex = currentReadPtr;
						[value release];
						continue;
					}
					[value release];
				}
				currentReadPtr++;
				break;
			case SKIP_TO_NEXT_LINE:
				if (((currentReadPtr + 2) < currentWritePtr) && 
					((local_buffer[currentReadPtr] == CARRIAGE_RETURN) && (local_buffer[currentReadPtr+1] == LINE_FEED))) {
					currentReadPtr += 2;
					markIndex = currentReadPtr;
					parserMode = BEGIN_NEW_LINE;
					continue;
				}
				currentReadPtr++;
				break;
			default:
				NSLog(@"Unknown parser mode: %d", parserMode);
		}
	} while (currentReadPtr < currentWritePtr);
	
	return 0;
}

- (void)resetConnection
{
	currentReadPtr = currentWritePtr = markIndex = 0;
	parserMode = SEARCH_METHOD;
	isRequestValid = NO;
	if (localRequest != nil) {
		[localRequest release];
		localRequest = nil;
	}
}

- (BOOL)readFromConnection:(int)connfd
{
	BOOL ret = NO;
	int read_cnt = -1;
	NSData *header=nil, *body=nil;
	int writ = 0;
	//BOOL flushConnectionNeeded = YES;
	BOOL toRelease = NO;
	HTTPUrlHelper* helper = nil;
	int body_size = 0;
	int write_size = 0;
	char *body_ptr = nil;
	//pthread_mutex_lock(&network_mutex);
	
	do {
		toRelease = NO;
		read_cnt = -1;
		writ = 0;
		[self resetConnection];
		
		do {
			read_cnt = read(connfd, local_buffer+currentWritePtr, (LOCAL_BUFFER_SIZE-currentWritePtr));
			if (read_cnt < 0) {
				NSLog(@"%s: %d, %s, %d", __func__, connfd, strerror(errno), broken_pipe_count);
				goto clean;
			}
			if (read_cnt > 0) {
				currentWritePtr += read_cnt;
				if ([self processRequestHeader:read_cnt] < 0) {
					goto clean;
				}
				else if (isRequestValid == YES) {
					break;
				}
			}
			else if (read_cnt == 0) {
				TRACE(">>>>> connection close: %d\n", connfd);
				goto clean;
			}
		} while (read_cnt > 0);
		
		if (isRequestValid == YES && localRequest != nil) {
			// process request
			if ([localRequest hasPrefix:@"/http"] == YES) {
				// this has original request
				helper = [self getResponseWithOrigUrl:[localRequest substringFromIndex:1] withHeader:&header withBody:&body toReleaseHeader:&toRelease]; 
				needToDisplaySplash = YES;
			}
			else {
				// TODO: get local file
				//   1. Check the cached file see if it is existed.
				//   2. If not, then get it from web.
				helper = [self getResponseWithFile:localRequest withHeader:&header withBody:&body toReleaseHeader:&toRelease];
				
				if (needToDisplaySplash == YES && [[localRequest pathExtension] compare:@"css"] != NSOrderedSame) {
					// CSS has been loaded, web page should appear now.
					//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(removeSplashView:) withObject:nil waitUntilDone:YES];
					needToDisplaySplash = NO;
				}
			}
			
			if (header == nil || body == nil) {
				//close(connfd);
				goto clean;
			}
			else {
				// write the header and body
				if ((writ = write(connfd, [header bytes], [header length])) != [header length]) {
					NSLog(@"%s: %d, %s, %d", __func__, connfd, strerror(errno), broken_pipe_count);
					goto clean;
				}
				
				if (body != nil) {
					body_size = [body length];
					body_ptr = (char*)[body bytes];
					while (body_size > 0) {
						if (body_size > CHUNKED_SIZE) 
							write_size = CHUNKED_SIZE;
						else
							write_size = body_size;
						if ((writ = write(connfd, body_ptr, write_size)) != write_size) {
							NSLog(@"%s: %d, %s, %d", __func__, connfd, strerror(errno), broken_pipe_count);
							goto clean;
						}
						body_size -= write_size;
						body_ptr += write_size;
					}
				}
				TRACE(">>>>> Writing response: fd: %d, header: %d, body: %d\n", connfd, [header length], [body length]);
				/*
				 NSString *dir = NSTemporaryDirectory();
				 dir = [dir stringByAppendingPathComponent:@"test.txt"];
				 int fd = open([dir UTF8String], O_RDWR | O_CREAT);
				 if (fd < 0) {
				 NSLog(@"Can't create a file, %s", strerror(errno));
				 }
				 write(fd, [header bytes], [header length]);
				 write(fd, [body bytes], [body length]);
				 close(fd);
				 NSLog(@"|||||||||| Creating file: %@", dir);
				 */
				//[header release];
			}
			
		}
		shutdown(connfd, SHUT_RDWR);
	} while (YES);
	
	ret = YES;
	
clean:
	close(connfd);
	if (helper != nil) {
		[helper finishConnection];
		[helper release];
	}
	
	if (toRelease == YES) {
		if (header)
			[header release];
		if (body)
			[body release];
	}
	
	//pthread_mutex_unlock(&network_mutex);
	return ret;
}

/*
 * getResponseWithOrigUrl:
 *   get the object either from internet or local file.
 *   There are two options:
 *     1. Do the normal operation and get the object from the files.
 *        In this case we will need to combine the response header and body.
 *     2. If we just get the object from Internet, we have everything in NSData form,
 *        so supply that and save the file as the last operation.
 */
- (HTTPUrlHelper*)getResponseWithOrigUrl:(NSString*)orig_url withHeader:(NSData**)header withBody:(NSData**)body toReleaseHeader:(BOOL*)release
{
	//HTTPUrlHelper *http = [network getHTTPService];
	HTTPUrlHelper *helper = nil;
	
	// TODO: different case when the cache is avialble.
	TRACE("%s, %s\n", __func__, [orig_url UTF8String]);
	helper = [self requestWithURLUseCache:orig_url responseHeader:header responseBody:body toReleaseHeader:release];
	
	return helper;
}

- (HTTPUrlHelper*)getResponseWithFile:(NSString*)file withHeader:(NSData**)header withBody:(NSData**)body toReleaseHeader:(BOOL*)release
{
	HTTPUrlHelper *helper = nil;
	if ([[file pathExtension] compare:@"zzz"] == NSOrderedSame) {
		NSLog(@"%s, shall not response: %s", __func__, [file UTF8String]);
		*body = theNotFoundBody;
		*header = theNotFoundResHeader;
		return nil;
	}
	
	int fd = open([file UTF8String], O_RDONLY);
	//NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:file];
	
	if (fd == -1) {
		TRACE(">>>>> %s: file does not exist, %s\n", __func__, [file UTF8String]);
		
		// file does not exist, get it from web
		NSRange range = [file rangeOfString:@"cache"];
		if (range.location == NSNotFound) {
			*body = theNotFoundBody;
			*header = theNotFoundResHeader;
			return nil;
		}

		//[file stringByReplacingCharactersInRange:range withString:@"index"];
		NSString *indexFile = [theCacheService getIndexDescriptorFromCacheFile:file]; 
		fd = open([indexFile UTF8String], O_RDONLY);
		if (fd == -1) {
			NSLog(@"%s, %s", __func__, strerror(errno));
			*body = theNotFoundBody;
			*header = theNotFoundResHeader;
			return nil;
		}
		NSData* urlData = [theCacheService readFromFileDescriptor:fd withBlockSize:512];//[handle readDataToEndOfFile];
		if (urlData == nil) {
			*body = theNotFoundBody;
			*header = theNotFoundResHeader;
			return nil;
		}
		
		// Because the orig url is written with 0x0a at the end of the url.
		NSString *url = [[NSString alloc] initWithBytes:[urlData bytes] length:[urlData length]-1 encoding:NSUTF8StringEncoding];
		[urlData release];

		if ((helper = [self requestWithURL:url fileToSave:file responseHeader:header responseBody:body toReleaseHeader:release]) == nil) {
			*body = theNotFoundBody;
			*header = theNotFoundResHeader;
			[url release];
			return nil;
		}
		//[*header retain];
		[url release];
	}
	else {
		TRACE(">>>>> %s: fd: %d, file exists: %s\n", __func__, fd, [file UTF8String]);
		*body = [theCacheService readFromFileDescriptor:fd withBlockSize:4096]; //[handle readDataToEndOfFile];
		close(fd);
		
		NSString *name = [file stringByAppendingString:@".req"];
		//handle = [NSFileHandle fileHandleForReadingAtPath:name];
		*header = [theCacheService readFromFile:name]; //[handle readDataToEndOfFile];
		
		if (body == nil || header == nil) {
			if (body) {
				[*body release];
			}
			if (header) {
				[*header release];
			}
			*body = theNotFoundBody;
			*header = theNotFoundResHeader;
		}
		else {
			*release = YES;
		}
		//[name release];
		
		return nil;
	}
	
	return helper;
}

- (HTTPUrlHelper*)requestWithURL:(NSString*)orig_url fileToSave:(NSString*)file responseHeader:(NSData**)header responseBody:(NSData**)body toReleaseHeader:(BOOL*)release
{
	BOOL shouldCleanLater = NO;
	HTTPUrlHelper *helper = nil;
	
	NSURL* url = [[NSURL alloc] initWithString:orig_url];
	if (url == nil) {
		NSLog(@"%s, url is nil for %@", __func__, orig_url);
		return nil;
	}
	helper = [[HTTPUrlHelper alloc] init];
	helper.connectionTimeout = LOCAL_SERVER_CONNECTION_TIMEOUT;
	[helper requestWithURL:url fileToSave:file parserKind:MREADER_FILE_TYPE feedIndex:nil shouldWait:NO];
	shouldCleanLater = [helper constructResponseWithHeader:header withBody:body toReleaseHeader:release];
	
	[url release];
	
	if (shouldCleanLater == NO) {
		[helper release];
		helper = nil;
	}
	return helper;
}

- (HTTPUrlHelper*)requestWithURLUseCache:(NSString*)orig_url responseHeader:(NSData**)header responseBody:(NSData**)body toReleaseHeader:(BOOL*)release
{
	BOOL shouldCleanLater = NO;
	HTTPUrlHelper *helper = nil;
	
	NSURL* url = [[NSURL alloc] initWithString:orig_url];
	// TODO: need to get indexPath from the current WebView.
	NSIndexPath *indexPath = [theNetworkService getIndexForURL:orig_url];
	helper = [[HTTPUrlHelper alloc] init];
	helper.connectionTimeout = LOCAL_SERVER_CONNECTION_TIMEOUT*3;
	[helper requestWithURLUseCache:url delegate:[theNetworkService getHtmlParser] parserKind:MREADER_HTML_PARSER feedIndex:indexPath shouldWait:NO];
	shouldCleanLater = [helper constructResponseWithHeader:header withBody:body toReleaseHeader:release];
	//[url release];
	[indexPath release];
	
	if (shouldCleanLater == NO) {
		// should release now
		[helper release];
		helper = nil;
	}
	return helper;
}	


- (void)main 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (localRequest != nil) {
		[localRequest release];
		localRequest = nil;
	}
	isRequestValid = NO;
	
	//[self resetConnection];
	//[self startLocalServer];
	if ([self readFromConnection:connectedFD] == YES) {
		currentReadPtr = currentWritePtr = markIndex = 0;
	}
	//close(connectedFD);
	
	if (localRequest != nil) {
		[localRequest release];
		localRequest = nil;
	}
	
	[pool release];
	
	[serverManager exitConnThread:self];
}

- (void)dealloc
{
	[theNotFoundBody release];
	[theNotFoundResHeader release];
	[super dealloc];
}
@end
