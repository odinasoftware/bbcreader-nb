//
//  GeoSession.m
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "GeoSession.h"
#import "FBConnect.h"
#import "MReader_Defs.h"
#import "FacebookConnect.h"
#import "BBCDefaults.h"

static GeoSession	*sharedGeoSession = nil;
NSString            *kAppId = @"154801851879";

@implementation GeoSession

@synthesize fbConnectAgent;
@synthesize facebook = _facebook;
@synthesize fbUserName;
@synthesize fbUID;

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
		fbConnectAgent = nil;
		_gotExtendedPermission = NO;
		_needToPublish = NO;
        _permission =  [[NSArray arrayWithObjects:
                          @"read_stream", @"publish_stream", @"offline_access",nil] retain];
	}
	
	return self;
}

- (void)publishPhotoToFacebook
{
	if (_gotExtendedPermission) {
        [self.facebook requestWithGraphPath:@"me" andDelegate:self];
		//[self.fbConnectAgent publishPhotoToFacebook];
		_needToPublish = YES;
	}
	else {
		_needToPublish = YES;
	}

}
#pragma mark EXTENDED PERMISSION
- (void)getExtendedPermission:(id)object 
{
	if (self.facebook == nil) {
		_facebook = [[Facebook alloc] initWithAppId:kAppId andDelegate:self];
        if ([BBCDefaults sharedBBCDefaultsInstance].accessToken &&
            [BBCDefaults sharedBBCDefaultsInstance].expirationDate) {
            self.facebook.accessToken = [BBCDefaults sharedBBCDefaultsInstance].accessToken;
            self.facebook.expirationDate = [BBCDefaults sharedBBCDefaultsInstance].expirationDate;
        }
		//self.facebook = _facebook;
    }
	
	if (_gotExtendedPermission == NO) {
		[self.facebook authorize:_permission];
	}

	TRACE("%s, %d\n", __func__, [self.facebook isSessionValid]);
}

#pragma mark FBSessionDelegate
- (void)getAuthorization:(id)object
{
	[self.facebook authorize:_permission];
}

- (void)fbDidLogin
{
	TRACE_HERE;
	_gotExtendedPermission = YES;
	[self.facebook requestWithGraphPath:@"me" andDelegate:self];
    [[BBCDefaults sharedBBCDefaultsInstance] fbSynchronize];
	//if (_needToPublish) {
	//	[self.fbConnectAgent publishPhotoToFacebook];
	//}
}

- (void)fbDidLogout
{
	TRACE_HERE;
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
	TRACE("%s, %d\n", __func__, cancelled);
}
#pragma mark -

#pragma mark FBRequestDelegate


- (void)request:(FBRequest*)request didLoad:(id)result 
{

	TRACE("%s, returns: %p\n", __func__, result);
	if ([result isKindOfClass:[NSArray class]]) {
		result = [result objectAtIndex:0];
	}

	self.fbUID = [result objectForKey:@"id"];
	self.fbUserName = [result objectForKey:@"name"];
	// Show user name
	TRACE("%s, Query returned id: %s, name: %s\n", __func__, [self.fbUID UTF8String], [self.fbUserName UTF8String]);
	
	//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(notifyLoggedin:) withObject:nil waitUntilDone:NO];	
	
	if (_needToPublish) {
		[self.fbConnectAgent publishPhotoToFacebook];
	}
}
#pragma mark -

- (void)dealloc
{
	[fbConnectAgent release];
	[fbUserName release];
	//[fbSession release];
	[super dealloc];
}


@end
