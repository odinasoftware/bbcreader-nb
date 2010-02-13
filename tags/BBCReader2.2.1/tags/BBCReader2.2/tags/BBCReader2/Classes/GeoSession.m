//
//  GeoSession.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoSession.h"
#import "FBConnect/FBConnect.h"
#import "FacebookConnect.h"
#import "MReader_Defs.h"

static GeoSession	*sharedGeoSession = nil;

@implementation GeoSession

@synthesize fbSession;
@synthesize fbUID;
@synthesize fbUserName;
@synthesize gotExtendedPermission;
@synthesize fbConnectAgent;

+ (GeoSession*)sharedGeoSessionInstance
{
	//@synchronized (self) {
	if (sharedGeoSession == nil) {
		[[self alloc] init];
	}
	//}
	return sharedGeoSession;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedGeoSession == nil) { 
			sharedGeoSession = [super allocWithZone:zone]; 
			return sharedGeoSession;
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

+ (FBSession*)getFBSession:(id)delegate
{
	GeoSession *session = [GeoSession sharedGeoSessionInstance];
	
	if (session.fbSession == nil)
		session.fbSession = [FBSession sessionForApplication:@"33863d742186df02f92aae1f0ba5caa8" secret:@"3bcde5c948bdb16e6391872b0dc8b0ea" delegate:delegate];
	
	if (delegate == nil && session.fbSession == nil) {
		NSLog(@"%s, FB Session is nil.", __func__);
	}
	
	return session.fbSession;
}

+ (FacebookConnect*)getFBAgent
{
	GeoSession *session = [GeoSession sharedGeoSessionInstance];
	FacebookConnect *agent = session.fbConnectAgent;
	
	if (agent == nil) {
		FacebookConnect *a = [[FacebookConnect alloc] init];
		session.fbConnectAgent = a;
		[a release];
		
		agent = session.fbConnectAgent;
	}
	
	return agent;
} 

-(id)init 
{
	self = [super init];
	if (self) {
		fbUID = 0;
		fbConnectAgent = nil;
	}
	
	return self;
}

#pragma mark EXTENDED PERMISSION
- (void)getExtendedPermission:(id)object 
{
	FBPermissionDialog* dialog = [[[FBPermissionDialog alloc] init] autorelease];
	if (object)
		dialog.delegate = object;
	else
		dialog.delegate = self;
	dialog.permission = @"status_update";
	[dialog show];	
}

- (void)request:(FBRequest*)request didLoad:(id)result 
{
	TRACE("%s, %s returns: %d\n", __func__, [request.method UTF8String], result);
	NSArray* users = result;
	if ([users count] > 0) {
		NSDictionary* user = [users objectAtIndex:0];
		self.fbUserName = [user objectForKey:@"name"];
		// Show user name
		NSLog(@"%s, Query returned %@", __func__, self.fbUserName);
	}
	else {
		NSLog(@"%s, Fail to get user name:\n", __func__);
	}
}

- (void)dialogDidSucceed:(FBDialog*)dialog 
{
	TRACE("%s, got the extended permission.\n", __func__);
	gotExtendedPermission = YES;
}

- (void)dialogDidCancel:(FBDialog*)dialog 
{
	TRACE("%s, user declines the extended permission.\n", __func__);
	gotExtendedPermission = NO;
}

- (void)logoutFBSessionWithNotification:(BOOL)notify
{
	GeoSession *session = [GeoSession sharedGeoSessionInstance];
	
	[session.fbSession logout];
	fbUID = 0;
	gotExtendedPermission = NO;
	
	if (notify == YES) {
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(notifyLoggedin:) withObject:nil waitUntilDone:NO];	
	}
}

#pragma mark -

- (void)dealloc
{
	[fbConnectAgent release];
	[fbUserName release];
	[fbSession release];
	[super dealloc];
}


@end
