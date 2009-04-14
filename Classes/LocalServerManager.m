//
//  LocalServerManager.m
//  BBCReader
//
//  Created by Jae Han on 12/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <fcntl.h>
#include <netinet/tcp.h>

#include "MReader_Defs.h"

#import "LocalServer.h"
#import "LocalServerManager.h"

#define MAX_LOCAL_SERVER_THREAD	4
#define LOCAL_PORT				9000
#define LISTENQ					32


static LocalServerManager *sharedLocalServerManager = nil;

@implementation LocalServerManager

+ (LocalServerManager*)sharedLocalServerManager
{
	@synchronized (self) {
		if (sharedLocalServerManager == nil) {
			[[self alloc] init];
		}
	}
	
	return sharedLocalServerManager;
}

+ (id)allocWithZone:(NSZone*)zone
{
	@synchronized (self) {
		if (sharedLocalServerManager == nil) {
			sharedLocalServerManager = [super allocWithZone:zone];
			return sharedLocalServerManager;
		}
	}
	return nil;
}

- (id)init 
{
	if ((self = [super init])) {
		waitForThread = [[NSCondition alloc] init];
		activeThread = 0;
	}
	
	return self;
}

- (void)startLocalServerManager
{
	int listenfd=-1, connfd=-1;
	struct sockaddr_in cliaddr, servaddr;
	unsigned int clilen = 0;
	int optval = 1;
	int onoff = 0;
	//int timeout = 1;
	//struct timeval timeout;
	//int rt=1;
	//int sendBuf = 61440;
	//int rcvBuf = 61440;
	//int len=sizeof(ttl);
	
	//timeout.tv_sec = 1;
	//timeout.tv_usec = 0;
	
	
	
	//TRACE("%s, ttl: %d\n", __func__, ttl);
	
	listenfd = socket(AF_INET, SOCK_STREAM, 0);
	
	/*
	if (setsockopt(listenfd, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl)) < 0) {
		TRACE("error in getsockopt: %s\n", strerror(errno));
	}*/
	/*
	if (setsockopt(listenfd, SOL_SOCKET, SO_RCVBUF, &rcvBuf, sizeof(int)) < 0) {
		NSLog(@"error in setsockopt: %s\n", strerror(errno));
	}
	
	if (setsockopt(listenfd, SOL_SOCKET, SO_SNDBUF, &sendBuf, sizeof(int)) < 0) {
		NSLog(@"error in setsockopt: %s\n", strerror(errno));
	}*/
	
	 
	//if (pipe(signal_pipe) < 0) {
	//	NSLog(@"%s: %s", __func__, strerror(errno));
	//	return;
	//}
	
	bzero(&servaddr, sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
	servaddr.sin_port = htons(LOCAL_PORT);
	setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));
	if (bind(listenfd, (const struct sockaddr*)&servaddr, sizeof(servaddr)) < 0) {
		NSLog(@"%s: %s", __func__, strerror(errno));
		return;
	}
	
	if (listen(listenfd, LISTENQ) < 0) {
		NSLog(@"%s: %s", __func__, strerror(errno));
		return;
	}
	
	for (;;) {
		@try {
			/*
			if (stopIt == YES) {
				NSLog(@"Stop request has been detected.");
				return;
			}
			 */
			
			//TRACE("~~~~ before accept ~~~~~~\n");
			if ((connfd = accept(listenfd, (struct sockaddr*)&cliaddr, &clilen)) < 0) {
				if (errno == EINTR)
					continue;
				else {
					NSLog(@"%s, accept error: %s", __func__, strerror(errno));
					continue;
				}
			}
			
			TRACE("LocalServer, accepting connection: %d\n", connfd);
			//setsockopt(connfd, SOL_SOCKET, SO_LINGER, &l_onoff, sizeof(l_onoff));
			if (setsockopt(connfd, IPPROTO_TCP, TCP_NODELAY, &onoff, sizeof(onoff)) < 0) {
				NSLog(@"%s, failed to set nodelay. %s", __func__, strerror(errno));
			}
			/*
			if (setsockopt(connfd, IPPROTO_TCP, TCP_MAXRT, (const void*)&timeout, sizeof(timeout)) < 0) {
				NSLog(@"%s, failed to set timeout. %s", __func__, strerror(errno));
			}*/
			/*
			if (setsockopt(connfd, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl)) < 0) {
				TRACE("error in getsockopt: %s\n", strerror(errno));
			}
			 */
			/*
			if (setsockopt(connfd, SOL_SOCKET, SO_RCVTIMEO, (const void*)&timeout, sizeof(timeout)) < 0) {
				NSLog(@"%s, failed to set timeout. %s", __func__, strerror(errno));
			}
			if (setsockopt(connfd, SOL_SOCKET, SO_SNDTIMEO, (const void*)&timeout, sizeof(timeout)) < 0) {
				NSLog(@"%s, failed to set timeout. %s", __func__, strerror(errno));
			}
			*/
			/*
			if (setsockopt(connfd, SOL_SOCKET, SO_RCVBUF, &rcvBuf, sizeof(int)) < 0) {
				NSLog(@"error in setsockopt: %s\n", strerror(errno));
			}
			
			if (setsockopt(connfd, SOL_SOCKET, SO_SNDBUF, &sendBuf, sizeof(int)) < 0) {
				NSLog(@"error in setsockopt: %s\n", strerror(errno));
			}*/
			
			
			
			LocalServer *server = [[LocalServer alloc] initWithManager:self connFD:connfd];
			[server start];
			
			if (++activeThread >= MAX_LOCAL_SERVER_THREAD) {
				[waitForThread lock];
				TRACE("%s, waiting for available thread.\n", __func__);
				[waitForThread wait];
				[waitForThread unlock];
				TRACE("%s, thread is available.\n", __func__);
			}
			
		} @catch (NSException *exception) {
			NSLog(@"%s: main: %@: %@", __func__, [exception name], [exception reason]);
		}
	}
	
	
}

- (void)exitConnThread:(id)thread
{
	if (--activeThread > 0) {
		activeThread = 0;
	}
	[waitForThread signal];
	[(LocalServer*)thread release];
}
	
- (void)main 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self startLocalServerManager];
	
	[pool release];
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
