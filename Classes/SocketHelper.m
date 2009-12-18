//
//  SocketHelper.m
//  NYTReader
//
//  Created by Jae Han on 9/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#include <sys/socket.h>
#include <sys/select.h>
#include <netdb.h>
#include <arpa/inet.h>

#import <CFNetwork/CFHost.h>

#import "SocketHelper.h"
#import "HeaderFieldValue.h"
#import "NetworkService.h"

//#define USE_COOKIE
#define MAX_HEADER_LINE		1024
#define MAX_RESPONSE_DATA	4096
#define HEADER_SEPARATOR	':'
#define BLANK				' '
#define CARRIAGE_RETURN		0x0d
#define LINE_FEED			0x0a
#define HTTP_PORT			80
#define HTTP_GET			"GET"
#define HTTP_11				"HTTP/1.1"
#define HTTP_10				"HTTP/1.0"
#define HTTP_200			"200"
#define HTTP_301			"301"
#define HTTP_302			"302"
#define CHUNKED_END			5
#define CIRCULAR_REDIRECTION 3
#define CONNECTION_CLOSE	"Connection: close\r\n"

#define MAX_RETRY			5

static unsigned char requestDelimiter[2] = {CARRIAGE_RETURN, LINE_FEED};

static DnsHelper *sharedDnsHelper = nil;

int networkError = 0;

BOOL isValidInt(unsigned char c)
{
	//for (int i=0; i<[value length]; ++i) {
		//unichar c = [value characterAtIndex:i];
		if (!(c >= 0x30 && c <= 0x39) &&
			!(c >= 0x41 && c <= 0x46) &&
			!(c >= 0x61 && c <= 0x66)) {
			return NO;
		}
	//}
			
	return YES;
}

BOOL shouldMoreData(unsigned char* data)
{
	BOOL ret = YES;
	if ((data[0] == 0x30) && (data[1] == 0x0d) && (data[2] == 0x0a) && (data[3] == 0x0d) && (data[4] == 0x0a)) {
		// this means that chunked data is ended.
		// 0
		// \r\n
		// \r\n
		ret = NO;
	}
	
	return ret;
}

int findRelativeIndex(const char* url)
{
	int index = -1;
	int slashCount = 0;
	
	for (int i=0; i<strlen(url); ++i) {
		if (url[i] == '/') {
			slashCount++;
		}
		if (slashCount == 3) {
			index = i;
			break;
		}
	}
	
	return index;
}

@implementation DnsHelper

+(DnsHelper*) sharedDnsHelperInstance 
{
	@synchronized (self) {
		if (sharedDnsHelper == nil) {
			[[self alloc] init];
		}
	}
	return sharedDnsHelper;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedDnsHelper == nil) { 
			sharedDnsHelper = [super allocWithZone:zone]; 
			return sharedDnsHelper; // assignment and return on first allocation 
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}


- (id)init
{
	if ((self = [super init])) {
		dnsCache = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	
	return self;
}

- (struct sockaddr*)getHostAddress:(NSString*)host
{
	CFStreamError *error = nil;
	//struct hostent	*hp = nil;
	//struct sockaddr_in *server_addr=nil;
	CFDataRef addr;
	
	if (host == nil) {
		NSLog(@"%s, host is nul.", __func__);
		return nil;
	}
	
	//@try {
	@synchronized (self) {
		CFHostRef hostReference = (CFHostRef) [dnsCache objectForKey:host];
		if (hostReference == nil) {
			//testReachability((char*)[host UTF8String]);
			
			hostReference = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)host);
			CFHostStartInfoResolution(hostReference, kCFHostAddresses, error);
			if (error != nil) {
				NSLog(@"%s, %@", __func__, error);
				return nil;
			}
			
			TRACE("%s, create an host entry: %s\n", __func__, [host UTF8String]);
			[dnsCache setObject:(id)hostReference forKey:host];
		}
		
		
		Boolean hasBeenResolved = FALSE;
		NSArray *dns_info = (NSArray*)CFHostGetAddressing(hostReference, &hasBeenResolved);
		
		if (hasBeenResolved == FALSE) {
			NSLog(@"%s, has not been resolbed yet.");
			return nil;
		}
		
		addr = (CFDataRef) [dns_info objectAtIndex:0];
		if (addr == nil) {
			NSLog(@"%s, say resolved, but can't get the addr.", __func__);
			return nil;
		}
	}
	//}@catch (NSException *exception) {
	//	NSLog(@"%s: main: %@: %@", __func__, [exception name], [exception reason]);
	//	return nil;
	//}
	
	return (struct sockaddr*) CFDataGetBytePtr(addr);
}

- (id)copyWithZone:(NSZone *)zone 
{ 
	return self; 
} 
- (id)retain 
{ 
	return self; 
} 
- (unsigned)retainCount 
{ 
	return UINT_MAX; //denotes an object that cannot be released 
} 
- (void)release 
{ 
	//do nothing 
} 
- (id)autorelease 
{ 
	return self; 
} 

@end


@implementation SocketHelper

- (id)init
{
	if ((self = [super init])) {
		requestHeader = [[NSMutableData alloc] initWithCapacity:256];
		responseHeaderHolder = [[NSMutableData alloc] initWithCapacity:256];
		tempHeader = [[NSMutableData alloc] initWithCapacity:256];
		responseBody = [[NSMutableData alloc] initWithCapacity:4096];
		headerFieldArray = [[NSArray alloc] initWithObjects:
							[[HeaderFieldValue alloc] init], 
							[[HeaderFieldValue alloc] init], 
							[[HeaderFieldValue alloc] init], 
							[[HeaderFieldValue alloc] init],
							[[HeaderFieldValue alloc] initWithExcludeString:@"chunked"],
							[[HeaderFieldValue alloc] initWithExcludeField:YES],
							[[HeaderFieldValue alloc] initWithExcludeField:YES isThisCookie:YES], 
							[[HeaderFieldValue alloc] initWithExcludeField:YES], nil];
		headerFieldValueArray = [[NSArray alloc] initWithObjects:@"content-length", 
								 @"content-encoding", 
								 @"location", 
								 @"content-type",
								 @"transfer-encoding", 
								 @"connection",
								 @"set-cookie",
								 @"keep-alive", nil];
		responseFields = [[NSDictionary alloc] initWithObjects:headerFieldArray forKeys:headerFieldValueArray];
		responseStatus = RESPONSE_NONE;
		currentIndex = markIndex = beginIndex = 0;
		parserMode = SEARCH_PROTOCOL_TYPE;
		contentLength = -1;
		keepAlive = NO;
		foundChunkPrefix = NO;
		isAlive = NO;
		redirectionCount = 0;
		dnsHelper = [DnsHelper sharedDnsHelperInstance];
		cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	}
	return self;
}

- (BOOL)isSocketActive
{
	return isAlive;
}

- (BOOL)createSocketWithHostName:(NSString*)host keepAlive:(BOOL)alive
{
	BOOL ret = YES;
	BOOL createSocket = NO;
	
	if (alive == NO) {
		createSocket = YES;
	}
	else if ((sockfd != -1) && (host_name != nil) && ([host_name compare:host] != NSOrderedSame)) {
		close(sockfd);
		createSocket = YES;
		// This will crash in the pool
		//[host_name release];
	}
	else if ((host_name == nil) || (sockfd == -1)) {
		createSocket = YES;
	}
	
	if (createSocket == YES) {
		if (sockfd == -1)
			close(sockfd);
		
		sockfd = socket(AF_INET, SOCK_STREAM, 0);
		if (sockfd == -1) {
			NSLog(@"error in creating socket: %s", strerror(errno));
		}
		else {
			// this will crash in the pool
			//if (host_name)
			//	[host_name release];
			
			host_name = [[NSString alloc] initWithString:host];
			
			//hp = (struct hostent*) CFDataGetBytePtr(dns_info);
			
			keepAlive = NO;
		}
	}
	else {
		keepAlive = YES;
	}
	
	[requestHeader setLength:0];
	
	isAlive = YES;
		
	return ret;
}

- (BOOL)createRequestWithURL:(NSURL*)url
{
	int i = 0;
	//const char* dest = [[url path] UTF8String];
	
	const char* dest = [[url absoluteString] UTF8String];
	int relativeIndex = findRelativeIndex(dest);
	if (relativeIndex == -1) {
		NSLog(@"%s, couldn't find relative path.", __func__);
		return NO;
	}
	
		
	TRACE("%s; URL: %s\n", __func__, dest);
	memcpy((void*) headerBuffer, HTTP_GET, strlen(HTTP_GET));
	i += strlen(HTTP_GET);
	headerBuffer[i++] = BLANK;
	memcpy((void*) (headerBuffer + i), &dest[relativeIndex], strlen(dest)-relativeIndex);
	i += (strlen(dest) - relativeIndex);
	//memcpy((void*) (headerBuffer + i), dest, strlen(dest));
	//i += strlen(dest);
	headerBuffer[i++] = BLANK;
	memcpy((void*) (headerBuffer + i), HTTP_11, strlen(HTTP_11));
	i += strlen(HTTP_11);
	headerBuffer[i++] = CARRIAGE_RETURN;
	headerBuffer[i++] = LINE_FEED;
	
	[requestHeader appendBytes:headerBuffer length:i];
	
	// Initialize respnse
	responseStatus = RESPONSE_NONE;
	currentIndex = markIndex = beginIndex = 0;
	parserMode = SEARCH_PROTOCOL_TYPE;
	contentLength = -1;
	[responseHeaderHolder setLength:0];
	[tempHeader setLength:0];
	
	// intialize field dictionary
	for (HeaderFieldValue *val in [responseFields objectEnumerator]) {
		[val reset];
	}
	
	return YES;
}

- (BOOL)addRequestHeader:(NSString*)header withValue:(NSString*)value
{
	int i = [header length];

	memcpy(headerBuffer, [header UTF8String], i);
	headerBuffer[i++] = HEADER_SEPARATOR;
	headerBuffer[i++] = BLANK;
	memcpy(headerBuffer+i, [value UTF8String], [value length]);
	i = i + [value length];
	headerBuffer[i++] = CARRIAGE_RETURN;
	headerBuffer[i++] = LINE_FEED;
	
	[requestHeader appendBytes:headerBuffer length:i];
	
	return YES;
}

- (void)finishRequestHeader
{
	[self addRequestHeader:@"Connection" withValue:@"keep-alive"];
	[self addRequestHeader:@"Host" withValue:host_name];
	
	[requestHeader appendBytes:requestDelimiter length:2];

}

- (NSData*)sendRequest:(MReaderParserType)type
{
	NSData *data = [self sendRequest];
	
	if (data && type == MREADER_XML_PARSER) {
		// see if the response is really xml
		NSString *value = [self getResponseHeaderValue:@"content-type"];
		if ([value compare:@"text/xml" options:NSCaseInsensitiveSearch] != NSOrderedSame) {
			NSLog(@"---> Expect xml reponse, but getting html. Will disregard this response.");
			[data release];
			data = nil;
		}
		[value release];
	}
	
	return data;
}

- (NSData*)sendRequest
{
	NSData *response = nil;
	char addr_buffer[64];
	struct timeval timeout;
	
	//struct sockaddr_in server_addr;
	
	struct sockaddr_in * server_addr = (struct sockaddr_in*) [dnsHelper getHostAddress:host_name];	
	//struct in_addr **pptr = (struct in_addr**) hp->h_addr_list;
	if (server_addr == nil)	{
		NSLog(@"%s, server addresss is nul. %@", __func__, host_name);
		return nil;
	}
	
	[self finishRequestHeader];
	
	if (keepAlive == NO) {
		//bzero(&server_addr, sizeof(server_addr));
		server_addr->sin_family = AF_INET;
		server_addr->sin_port = htons(HTTP_PORT);
		//memcpy(&server_addr.sin_addr, *pptr, sizeof(struct in_addr));
		
		TRACE("trying to connect to %s\n", inet_ntop(AF_INET, &server_addr->sin_addr, addr_buffer, 64));
		
		if (connect(sockfd, (const struct sockaddr *) server_addr, sizeof(struct sockaddr)) == -1) {
			if (errno == ENETUNREACH || errno == EHOSTUNREACH) {
				networkError++;
				[NetworkService sharedNetworkServiceInstance].requireConnection = YES;
			}
			NSLog(@"socket connection failed: %s", strerror(errno));
			return nil;
		}
	}
	
	timeout.tv_sec = 30;
	timeout.tv_usec = 0;
	
	// set timeout for the socket
	if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (const void*)&timeout, sizeof(timeout)) < 0) {
		NSLog(@"%s, failed to set timeout. %s", __func__, strerror(errno));
	}
	if (setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, (const void*)&timeout, sizeof(timeout)) < 0) {
		NSLog(@"%s, failed to set timeout. %s", __func__, strerror(errno));
	}
	
	if (write(sockfd, [requestHeader bytes], [requestHeader length]) < 0) {
		NSLog(@"fail to write data: %s", strerror(errno));
	}
	
	// waiting for response
	int maxfd;
	fd_set rset;
	int select_continue = YES;
	//int nready = -1;
	int read_size = -1;
	
	FD_ZERO(&rset);
	FD_SET(sockfd, &rset);
	maxfd = sockfd;
	BOOL error = NO;
	int retry = 0;
	
	do {
		if (FD_ISSET(sockfd, &rset)) {
			// response available
			if ((read_size = read(sockfd, responseBuffer, MAX_RESPONSE_DATA)) < 0) {
				NSLog(@"read failed: %s", strerror(errno));
				if (retry < MAX_RETRY && errno == EAGAIN) {
					select_continue = YES;
					error = NO;
					retry++;
					continue;
				}
				else {
					select_continue = NO;
					error = YES;
				}
				break;
			}
			else if (read_size == 0) {
				NSLog(@"%s: connection closed.: %d", __func__, sockfd);
				select_continue = NO;
				break;
			}
			
			select_continue = [self processResponse:responseBuffer withLength:read_size];
			
			//NSLog(@"read: %d", read_size);
			
		}
		//}
	} while (select_continue);
	
	if (error == NO) {
		response = [self getResponseData];
	}
				  
	return response;
}

- (void)close
{
	close(sockfd);
	sockfd = -1;
	redirectionCount = 0;
	[host_name release];
	host_name = nil;
}

- (void)findResponseField
{
	NSString *fieldName = nil;
	NSString *fieldValue = nil;
	const char* response = (const char*) [tempHeader bytes];
	int size = [tempHeader length];
	BOOL cont = YES;
	BOOL excludeThisLine = NO;
	BOOL connectionCloseAdded = NO;
	
	do {
		switch (parserMode) {
			case SEARCH_PROTOCOL_TYPE:
				markIndex = beginIndex = 0;
				responseStatus = RESPONSE_START;
				if (response[currentIndex] == ' ') {
					NSString *protocol = [[NSString alloc] initWithBytes:&response[markIndex] length:currentIndex - markIndex encoding:NSUTF8StringEncoding];
					if (([protocol compare:@HTTP_11] == NSOrderedSame) || ([protocol compare:@HTTP_10] == NSOrderedSame)) {
						currentIndex++;
						markIndex = currentIndex;
						parserMode = SEARCH_GET_RESULT;
						[protocol release];
						continue;
					}
					else {
						NSLog(@"Unsupported protocol found: %@", protocol);
						responseStatus = RESPONSE_UNSUPPORTED;
						cont = NO;
						[protocol release];
						break;
					}
				}
				
				currentIndex++;
				break;
			case SEARCH_GET_RESULT:
				if (response[currentIndex] == ' ') {
					NSString *result = [[NSString alloc] initWithBytes:&response[markIndex] length:currentIndex - markIndex encoding:NSUTF8StringEncoding];
					if ([result compare:@HTTP_200] == NSOrderedSame) {
						parserMode = SKIP_TO_NEXT_LINE;
						responseStatus = RESPONSE_OK;
						[result release];
						continue;
					}
					else if (([result compare:@HTTP_302] == NSOrderedSame)) {
						TRACE("Redirection is requested.\n");
						parserMode = SKIP_TO_NEXT_LINE;
						responseStatus = RESPONSE_REDIRECT;
						[result release];
						continue;
					}
					else if (([result compare:@HTTP_301] == NSOrderedSame)) {
						TRACE("Move permanently is requested.\n");
						parserMode = SKIP_TO_NEXT_LINE;
						responseStatus = RESPONSE_MOVE_PERMANENTLY;
						[result release];
						continue;
					}
					else {
						NSLog(@"Unsupported response: %@", result);
						responseStatus = RESPONSE_NOT_FOUND;
						parserMode = SKIP_TO_NEXT_LINE;
						//cont = NO;
						[result release];
						//break;
						continue;
					}
					[result release];
				}
				
				currentIndex++;
				
				break;
			case BEGIN_NEW_LINE:
				markIndex = currentIndex;
				if (((currentIndex + 1) < size) && 
					((response[currentIndex] == CARRIAGE_RETURN) && (response[currentIndex+1] == LINE_FEED))) {
					currentIndex += 2;
					parserMode = BODY_FOUND;
					cont = NO;
					break;
				}
				else {
					parserMode = SEARCH_FIELD;
				}
				break;
			case SEARCH_FIELD:
				if (response[currentIndex] == ':') {
					// found a field
					fieldName = [[NSString alloc] initWithBytes:&response[markIndex] length:currentIndex - markIndex encoding:NSUTF8StringEncoding];
					currentValue = [responseFields objectForKey:[fieldName lowercaseString]];
					
					//if ([fieldName caseInsensitiveCompare:@"connection"] == NSOrderedSame) {
					//	printf("here");
					//}
					//NSLog(@"found response header: %@", fieldName);
					[fieldName release];
					currentIndex++;
					if (currentValue != nil) {
						markIndex = currentIndex;
						parserMode = SEARCH_VALUE;
						continue;
					}
					else {
						parserMode = SKIP_TO_NEXT_LINE;
						continue;
					}
				}
				currentIndex++;
				break;
			case SEARCH_VALUE:
				if (((currentIndex + 1) < size) && 
					((response[currentIndex] == CARRIAGE_RETURN) && (response[currentIndex+1] == LINE_FEED))) {
					fieldValue = [[NSString alloc] initWithBytes:&response[markIndex] length:currentIndex - markIndex encoding:NSUTF8StringEncoding];
				
					if ([currentValue fillValue:fieldValue] == NO) {
						// need to exclude this field;
						excludeThisLine = YES;
					}
				
					//[fieldValue release];
					currentIndex += 2;
					parserMode = BEGIN_NEW_LINE;
					break;
				}
				else if (currentIndex == markIndex && response[currentIndex] == ' ') {
					// only prepending blank
					markIndex++;
				}
				
				currentIndex++;
				break;
			case SKIP_TO_NEXT_LINE:
				if (((currentIndex + 1) < size) && 
					((response[currentIndex] == CARRIAGE_RETURN) && (response[currentIndex+1] == LINE_FEED))) {
					currentIndex += 2;
					parserMode = BEGIN_NEW_LINE;
					break;
				}
				currentIndex++;
				break;
			case BODY_FOUND:
				break;
			default:
				NSLog(@"Unknown parser mode: %d", parserMode);
		}
#ifdef USE_COOKIE
		if ([currentValue isThisCookie]) {
			// set Cookie here
			[self setCookie:[currentValue getValue]];
		}
#endif
		
		if (excludeThisLine == NO && (parserMode == BEGIN_NEW_LINE || parserMode == BODY_FOUND)) {
			// add the previous line to the responseHeader
			[responseHeaderHolder appendBytes:&response[beginIndex] length:currentIndex-beginIndex];
			//NSLog(@"%s, add this line: %d %d", __func__, beginIndex, currentIndex);
			beginIndex = currentIndex;
		}
		else if (excludeThisLine == YES && parserMode == BEGIN_NEW_LINE) {
			// exclude this line.
			excludeThisLine = NO;
			beginIndex = currentIndex;
			if (connectionCloseAdded == NO) {
				[responseHeaderHolder appendBytes:CONNECTION_CLOSE length:strlen(CONNECTION_CLOSE)];
				connectionCloseAdded = YES;
			}
		}
		
	} while ((cont == YES) && (currentIndex < size));
	
	if ((parserMode == BODY_FOUND) && (responseStatus == RESPONSE_OK)) {
		HeaderFieldValue *headerValue = [responseFields objectForKey:@"transfer-encoding"];
		NSString *encondig = [headerValue getValue];
	
		if ((encondig != nil) && ([encondig compare:@"chunked"] == NSOrderedSame)) {
			responseStatus = RESPONSE_CHUNKED;			
			TRACE("Body found: chunked encoding. size: %d, cur: %d\n", size, currentIndex);
			[tempHeader setLength:currentIndex];
	
			foundChunkPrefix = YES;
			chunkedParserMode = CHUNKED_NUM;
			chunkedLenIndex = 0;
			[self processChunkedBody:(char*)&response[currentIndex] length:size-currentIndex];
			//[responseBody appendBytes:&response[currentIndex] length:size-currentIndex];
		}
		else {
			headerValue = [responseFields objectForKey:@"content-length"];
		
			NSString *len = [headerValue getValue];
			contentLength = (len!=nil?[len intValue]:0);
			TRACE("Body found: %d\n", contentLength);
			[tempHeader setLength:currentIndex];
			[responseBody appendBytes:&response[currentIndex] length:size-currentIndex];
		}
				
	}
	else if ((parserMode == BODY_FOUND) && (responseStatus == RESPONSE_NOT_FOUND)){
		/*
		HeaderFieldValue *headerValue = [responseFields objectForKey:@"content-length"];
		
		NSString *len = [headerValue getValue];
		contentLength = (len!=nil?[len intValue]:0);
		TRACE("Body found: %d\n", contentLength);
		[tempHeader setLength:currentIndex];
		[responseBody appendBytes:&response[currentIndex] length:size-currentIndex];
		 */
		// don't do anything if the response is 404
		[responseBody setLength:0];
	}
		
}

- (NSString*)getResponseHeaderValue:(NSString*)field
{
	NSString *ret = nil;
	
	HeaderFieldValue *responseHeader = [responseFields objectForKey:[field lowercaseString]];
	if (responseHeader != nil) {
		ret = responseHeader.value;
	}
	
	return ret;
}

/*
 * processChunkedBody
 *    find the length and the following body.
 *    when it finds the length, it will try to add the exact amount to the response body.
 *    however many case, it does not exactly match the length in the prefix. 
 *    sometmes have to read more than the amount indicated to detect the next body.
 */

- (BOOL)processChunkedBody:(char*)data length:(int)len
{
	BOOL ret = YES;
	int	chunkedCurrentIndex=0;
	int	chunkedMarkIndex=0;
	BOOL foundChunkedLen = NO;

	//NSLog(@"%s, ? %x %x %x %x", __func__, data[0], data[1], data[2], data[3]);
	
	@try {
		while (chunkedCurrentIndex < len) {	
			
			// find the length of the following body
			if (chunkedBodyLength == 0) {
				chunkedMarkIndex = chunkedCurrentIndex;
				do {
					
					switch (chunkedParserMode) {
						case CHUNKED_DATA:
							if (data[chunkedCurrentIndex] == CARRIAGE_RETURN) {
								chunkedParserMode = CHUNKED_CR;
							}
							chunkedMarkIndex = chunkedCurrentIndex;
							break;
						case CHUNKED_CR:
							if (data[chunkedCurrentIndex] == LINE_FEED)
								chunkedParserMode = CHUNKED_LF;
							else
								chunkedParserMode = CHUNKED_DATA;
							break;
						case CHUNKED_LF:
							if (isValidInt(data[chunkedCurrentIndex]) == YES) {
								chunkedParserMode = CHUNKED_NUM;
								chunkedLenIndex = 0;
								intLenBuffer[chunkedLenIndex] = data[chunkedCurrentIndex];
								chunkedLenIndex++;
							}
							else {
								chunkedParserMode = CHUNKED_DATA;
							}
							break;
						case CHUNKED_NUM:
							if (data[chunkedCurrentIndex] == CARRIAGE_RETURN)
								chunkedParserMode = CHUNKED_CR2;
							else {
								if (isValidInt(data[chunkedCurrentIndex]) == NO) {
									chunkedParserMode = CHUNKED_DATA;
								}
								else {
									intLenBuffer[chunkedLenIndex] = data[chunkedCurrentIndex];
									chunkedLenIndex++;
								}
							}
							break;
						case CHUNKED_CR2:
							if (data[chunkedCurrentIndex] == LINE_FEED)
								chunkedParserMode = CHUNKED_LF2;
							else {
								chunkedParserMode = CHUNKED_DATA;
								break;
							}
						case CHUNKED_LF2:
							if (chunkedLenIndex < 6) {
								chunkedParserMode = CHUNKED_LEN_DETECTED;
							}
							else {
								chunkedParserMode = CHUNKED_DATA;
								break;
							}
						case CHUNKED_LEN_DETECTED:
							intLenBuffer[chunkedLenIndex]='\0';
							chunkedBodyLength = strtol(intLenBuffer, NULL, 16);
							if (chunkedBodyLength == 0 && strcmp(intLenBuffer, "0") != 0) {
								// this does not have length
								chunkedParserMode = CHUNKED_DATA;
							}
							else {
								// this has right length
								foundChunkedLen = YES;
								//NSLog(@"Found a chunked body: %d, %d, %d, %@", chunkedMarkIndex, chunkedCurrentIndex, chunkedBodyLength, token);
							}
							
							break;
						default:
							NSLog(@"unknown chunked parser mode: %d", chunkedParserMode);
					}
								
					chunkedCurrentIndex += 1;
					
					if (foundChunkedLen == YES) 
						break;
					
					if (chunkedParserMode == CHUNKED_DATA)
						[responseBody appendBytes:&data[chunkedMarkIndex] length:chunkedCurrentIndex - chunkedMarkIndex];
				} while (chunkedCurrentIndex < len);
			}
			
			if ((chunkedBodyLength > 0) || foundChunkedLen == YES) {
				if (chunkedBodyLength == 0) {
					// found the end of the chunked body.
					return NO;
				}
				
				// add only data to the response body
				if (chunkedBodyLength >= (len - chunkedCurrentIndex)) {
					// will have to wait for another call, expecting more data
					[responseBody appendBytes:&data[chunkedCurrentIndex] length:len-chunkedCurrentIndex];
					chunkedBodyLength -= (len- chunkedCurrentIndex);
					chunkedCurrentIndex = len;
				}
				else {
					// have enough data for the chunked body, see if we have other chunked body.
					[responseBody appendBytes:&data[chunkedCurrentIndex] length:chunkedBodyLength];
					chunkedCurrentIndex += chunkedBodyLength;
					chunkedBodyLength = 0;
					chunkedParserMode = CHUNKED_DATA;
					
				}
				foundChunkedLen = NO;
			}
			//TRACE("chunked, mark: %d, cur: %d, body: %d, len: %d\n", chunkedMarkIndex, chunkedCurrentIndex, chunkedBodyLength, len);
			
		}
	}
	@catch (NSException *exception) {
		NSLog(@"%s: %@: %@", __func__, [exception name], [exception reason]);
	}
	
	//NSLog(@"%s, %d", __func__, chunkedBodyLength);
	return ret;
}

- (NSData*)redirectRequestToURL:(NSURL*) url useConnection:(BOOL)connectionAlive
{
	// redirect
	[self createSocketWithHostName:[url host] keepAlive:connectionAlive];
	[self createRequestWithURL:url];
	[self addRequestHeader:@"User-Agent" withValue:@"Mozilla/5.0 (iPhone Simulator; U; CPU iPhone OS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20"];
	[self addRequestHeader:@"Accept-Encoding" withValue:@"gzip, deflate"];
	[self addRequestHeader:@"Accept" withValue:@"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"];
	
#ifdef USE_COOKIE
	NSString *cookie = [self getCookie:url];
	if (cookie) {
		[self addRequestHeader:@"Cookie" withValue:cookie];
		[cookie release];
	}
#endif

	[url release];
	return [self sendRequest];
}

- (BOOL)processResponse:(unsigned char*)data withLength:(int)length
{
	BOOL ret = YES;
	
	//TRACE("%s: length, %d\n", __func__, length);
	
	if (responseStatus == RESPONSE_UNSUPPORTED) {
		return NO;
	}
	
	if ((parserMode == BODY_FOUND) && (responseStatus == RESPONSE_OK)) {
		if (contentLength <= 0) {
			NSLog(@"Body found, but no legnth set,");
			return NO;
		}
		[responseBody appendBytes:data length:length];
		if ([responseBody length] >= contentLength) {
			ret = NO;
		}
	}
	else if ((parserMode == BODY_FOUND) && ((responseStatus == RESPONSE_REDIRECT) || (responseStatus == RESPONSE_MOVE_PERMANENTLY))) {
		ret = NO;
	}
	else if ((parserMode == BODY_FOUND) && (responseStatus == RESPONSE_CHUNKED)) {
		//[responseBody appendBytes:data length:length];
		[self processChunkedBody:(char*)data length:length];
		// check there is end or not.
		ret = shouldMoreData(&data[length-CHUNKED_END]);
	}
	else if ((responseStatus == RESPONSE_START) || (responseStatus == RESPONSE_NONE)){
		[tempHeader appendBytes:data length:length];
		[self findResponseField];
		
		if (responseStatus == RESPONSE_NOT_FOUND) {
			ret = NO;
		}
		else if ((parserMode == BODY_FOUND) && ([responseBody length] >= contentLength)) {
			ret = NO;
		}
		else if ((parserMode == BODY_FOUND) && ((responseStatus == RESPONSE_REDIRECT) || (responseStatus == RESPONSE_MOVE_PERMANENTLY))) {
			ret = NO;
		}
	}
	else if (responseStatus == RESPONSE_NOT_FOUND) {
		ret = NO;
	}
	
	return ret;
	
}

- (NSData*)getResponseData
{
	NSData *data = nil;
	
	if ((parserMode == BODY_FOUND) && ((responseStatus == RESPONSE_REDIRECT) || (responseStatus == RESPONSE_MOVE_PERMANENTLY))) {
		// redirect requested.
		[responseBody setLength:0];
		redirectionCount++;
		if (redirectionCount > CIRCULAR_REDIRECTION) {
			NSLog(@"Circular redirection detected.");
			return nil;
		}
		
		HeaderFieldValue *location = [responseFields objectForKey:@"location"];
		NSString *loc = [location getValue];
		TRACE("Redirect to: %s, %d\n", [loc UTF8String], redirectionCount);
		//data = [self redirectRequestToURL:[[NSURL alloc] initWithString:loc] useConnection:(responseStatus == RESPONSE_REDIRECT?YES:NO)];
		data = [self redirectRequestToURL:[[NSURL alloc] initWithString:loc] useConnection:YES];
	}
	else {
		//[responseBody retain];
		data = responseBody;
	
		//responseBody = [[NSMutableData alloc] initWithCapacity:4096];
	}
	
	return data;
}

- (NSData*)getResponseHeader
{
	return responseHeaderHolder;
}

- (NSString*)getCookie:(NSURL*)url
{
	NSArray *cookies = [cookieStorage cookiesForURL:url];
	NSHTTPCookie *entry = nil;
	NSMutableString *cookiesString = nil;
	NSString *cookieEntry = nil;
	
	for (int i=0; i<[cookies count]; ++i) {
		entry = [cookies objectAtIndex:i];
		if (entry) {
			cookieEntry = [[NSString alloc] initWithFormat:@"%@=%@", [entry name], [entry value]];
			
			if (cookiesString == nil) {
				cookiesString = [[NSMutableString alloc] initWithString:cookieEntry];
			}
			else {
				[cookiesString appendFormat:@"; %@=%@", [entry name], [entry value]];
			}
			[cookieEntry release];
		}
	}
	
	TRACE("%s: cookie : %s\n", __func__, [cookiesString UTF8String]);
	return cookiesString;
}

- (void)setCookie:(NSString*)cookie
{
	int start=0;
	char *ptr = (char*)[[cookie dataUsingEncoding:NSUTF8StringEncoding] bytes];
	NSString *name = nil;
	NSString *value = nil;
	NSMutableDictionary *cookieProperty = [[NSMutableDictionary alloc] init];
	int i = 0;
	BOOL foundName = NO;
	BOOL foundCookieName = NO;
	
	do {
		if (foundName == NO && ptr[i] == ' ') {
			++i;
			start = i;
		}
		else if (ptr[i] == '=') {
			name = [[NSString alloc] initWithBytes:&ptr[start] length:i-start encoding:NSUTF8StringEncoding];
			++i;
			start = i;
			foundName = YES;
		}
		else if (ptr[i] == ';') {
			value = [[NSString alloc] initWithBytes:&ptr[start] length:i-start encoding:NSUTF8StringEncoding];
			++i;
			start = i;
			if (foundCookieName == NO) {
				foundCookieName = YES;
				[cookieProperty setObject:name forKey:NSHTTPCookieName];
				[cookieProperty setObject:value forKey:NSHTTPCookieValue];
				//TRACE("%s, name: %s, value: %s\n", __func__, [name UTF8String], [value UTF8String]);
			}
			else if ([name compare:@"domain"] == NSOrderedSame) {
				[cookieProperty setObject:value forKey:NSHTTPCookieDomain];
				//TRACE("%s, domain: %s\n", __func__, [value UTF8String]);
			}
			else if ([name compare:@"path"] == NSOrderedSame) {
				[cookieProperty setObject:value forKey:NSHTTPCookiePath];
				//TRACE("%s, path: %s\n", __func__, [value UTF8String]);
			}
			else if ([name compare:@"expires"] == NSOrderedSame) {
				[cookieProperty setObject:value forKey:NSHTTPCookieExpires];
				//TRACE("%s, expires: %s\n", __func__, [value UTF8String]);
			}
			else {
				TRACE("%s: name: %s, value: %s\n", __func__, [name UTF8String], [value UTF8String]);
			}
			foundName = NO;
			
			[name release];
			[value release];
		}
		else {
			++i;
		}
		
	} while (i < [cookie length]);
	
	NSHTTPCookie *httpCookie = [NSHTTPCookie cookieWithProperties:cookieProperty];
	[cookieProperty release];
	[cookieStorage setCookie:httpCookie];
}

- (void)dealloc
{
	[requestHeader release];
	[responseHeaderHolder release];
	[tempHeader release];
	[responseBody release]; 
	[responseFields release];
	
	for (HeaderFieldValue *value in headerFieldArray) {
		[value release];
	}
	[headerFieldArray release];
	[headerFieldValueArray release];
							
	[super dealloc];
}

@end
