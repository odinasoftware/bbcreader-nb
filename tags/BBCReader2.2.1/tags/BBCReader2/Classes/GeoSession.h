//
//  GeoSession.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect/FBConnect.h"

#define FB_GET_USERNAME			@"facebook.fql.query"

@class FacebookConnect;

@interface GeoSession : NSObject <FBDialogDelegate, FBRequestDelegate> {
	FBSession			*fbSession;
	FBUID				fbUID;
	NSString			*fbUserName;
	
	BOOL				gotExtendedPermission;
	FacebookConnect		*fbConnectAgent;
}

@property (nonatomic, retain) FBSession			*fbSession;
@property (nonatomic, retain) NSString			*fbUserName;
@property (nonatomic, retain) FacebookConnect	*fbConnectAgent;

@property (nonatomic) BOOL						gotExtendedPermission;
@property (nonatomic) FBUID						fbUID;



+ (GeoSession*)sharedGeoSessionInstance;
+ (FBSession*)getFBSession:(id)delegate;
+ (FacebookConnect*)getFBAgent;

- (void)getExtendedPermission:(id)object;
- (void)logoutFBSessionWithNotification:(BOOL)notify;

@end
