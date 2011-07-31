//
//  FacebookConnect.h
//  GeoJournal
//
//  Created by Jae Han on 9/5/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

typedef enum {FB_REQUEST_NONE=0, FB_REQUEST_LOGIN=1, FB_REQUEST_USERNAME=2, FB_REQUEST_PERMISSION=3, FB_UPLOAD_PICTURE=4, FB_UPLOAD_STORY=5} FBRequestType;

@class Journal;
@class WebLink;

@interface FacebookConnect : NSObject <FBDialogDelegate, FBRequestDelegate, FBSessionDelegate> {
	WebLink				*webLink;
	UIImage				*imageForLink;
	
	@private
	FBRequestType		_fbCallType;
	UIAlertView			*_alertView;
	BOOL				_notifySuccess;
}

@property (nonatomic, retain) UIImage			*imageForLink;
@property (nonatomic, retain) WebLink			*webLink; 
@property (nonatomic, retain) UIAlertView		*_alertView;

- (void)publishToFacebook:(NSString*)image_url;
- (void)publishToFacebookForWebLink:(WebLink*)w;

- (void)publishPhotoToFacebook;
- (void)loginToFacebookWithNotification:(BOOL)notify;

@end
