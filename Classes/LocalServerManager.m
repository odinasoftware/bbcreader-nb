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

#define MAX_LOCAL_SERVER_THREAD	6
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
	BOOL get_new_socket = NO;	
	
	
	//TRACE("%s, ttl: %d\n", __func__, ttl);
	
    for (;;) {
        listenfd = socket(AF_INET, SOCK_STREAM, 0);
		
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
        
        do {
            @try {
                              
                //TRACE("~~~~ before accept ~~~~~~\n");
                if ((connfd = accept(listenfd, (struct sockaddr*)&cliaddr, &clilen)) < 0) {
                    if (errno == EINTR)
                        continue;
                    else {
                        NSLog(@"%s, accept error: %s", __func__, strerror(errno));
                        get_new_socket = YES;
                        continue;
                    }
                }
                
                TRACE("LocalServer, accepting connection: %d\n", connfd);
                //setsockopt(connfd, SOL_SOCKET, SO_LINGER, &l_onoff, sizeof(l_onoff));
                if (setsockopt(connfd, IPPROTO_TCP, TCP_NODELAY, &onoff, sizeof(onoff)) < 0) {
                    NSLog(@"%s, failed to set nodelay. %s", __func__, strerror(errno));
                }
                         
                LocalServer *server = [[LocalServer alloc] initWithManager:self connFD:connfd];
                TRACE("Starting thread: %p\n", server);
                [server start];
                [server release];
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
        } while (get_new_socket == NO);
        close(listenfd);
        NSLog(@"Close %d and restart socket.\n", listenfd);
    }
	
}

- (void)exitConnThread:(id)thread
{
    TRACE("%s, id: %p, %d\n", __func__, thread, [(LocalServer*)thread retainCount]);
	//if (--activeThread < 0) {
	//	activeThread = 0;
	//}
    --activeThread;
	[waitForThread signal];
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
