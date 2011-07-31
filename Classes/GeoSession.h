//
//  GeoSession.h
//  GeoJournal
//
//  Created by Jae Han on 7/15/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

#define FB_GET_USERNAME			@"facebook.fql.query"

@class FacebookConnect;

@interface GeoSession : NSObject <FBDialogDelegate, FBRequestDelegate, FBSessionDelegate> {
	NSString			*fbUserName;
	NSString			*fbUID;
	Facebook			*_facebook;
	BOOL				_gotExtendedPermission;
	FacebookConnect		*fbConnectAgent;
	NSArray				*_permission;
	BOOL				_needToPublish;
}

@property (nonatomic, retain) FacebookConnect	*fbConnectAgent;
@property (nonatomic, retain) Facebook			*facebook;
@property (nonatomic, retain) NSString			*fbUserName;
@property (nonatomic, retain) NSString			*fbUID;



+ (GeoSession*)sharedGeoSessionInstance;
+ (FacebookConnect*)getFBAgent;

- (void)getExtendedPermission:(id)object;
- (void)logoutFBSessionWithNotification:(BOOL)notify;
- (void)getAuthorization:(id)object;
- (void)publishPhotoToFacebook;

@end
