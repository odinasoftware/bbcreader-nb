//
//  LocalServerManager.h
//  BBCReader
//
//  Created by Jae Han on 12/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LocalServer;

@interface LocalServerManager : NSThread {
	NSInteger	activeThread;
	NSCondition	*waitForThread;
}

- (void)startLocalServerManager;
- (void)exitConnThread:(id)thread;

@end
