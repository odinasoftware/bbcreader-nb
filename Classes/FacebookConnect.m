//
//  FacebookConnect.m
//  GeoJournal
//
//  Created by Jae Han on 9/5/09.
//  Copyright 2009 Home. All rights reserved.
//

#import "FacebookConnect.h"
#import "GeoSession.h"
#import "FBConnect/FBFeedDialog.h"
#import "MReader_Defs.h"
#import "WebLink.h"

#define LINE_FEED							0x0A
#define CARRIAGE_RETURN						0x0D
#define BLANK								@" "

extern NSString *getImageHrefForFacebook(float latitude, float longitude);

NSString *getJASONSafeString(NSString *string) {
	/*
	NSMutableData *stringData = [[NSMutableData alloc] initWithCapacity:[string length]];
	
	char *data = (char*) [string UTF8String];
	
	for (int i=0; i<[string length]; ++i) {
		if (data[i] != LINE_FEED && data[i] != CARRIAGE_RETURN) {
			[stringData appendBytes:&data[i] length:1];
		}
	}
	
	NSString *safe = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
	 */
	NSMutableString *safe = [[NSMutableString alloc] initWithCapacity:[string length]];
	NSRange subRange = NSMakeRange(0, [string length]);
	NSRange searchRange = NSMakeRange(0, [string length]);
	NSRange range;
	
	do {
		range = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSCaseInsensitiveSearch range:searchRange];
		if (range.location == NSNotFound) {

			[safe appendString:[string substringWithRange:searchRange]];
		}
		else {
			subRange.location = searchRange.location;
			subRange.length = range.location - searchRange.location;
			[safe appendString:[string substringWithRange:subRange]];
			[safe appendString:BLANK];

			searchRange.location = range.location+1;
			searchRange.length = [string length] - searchRange.location;
		}
		
	} while (range.location != NSNotFound && searchRange.location < [string length]);
	
	TRACE("%s, %s\n", __func__, [safe UTF8String]);
	return safe;
}

@implementation FacebookConnect

@synthesize webLink;
@synthesize imageForLink;
@synthesize _alertView;

- (id)init
{
	if (self = [super init]) {
		_fbCallType = FB_REQUEST_NONE;
	}
	
	return self;
}

/*
 * The templateData property is a string and cannot contain any carriage returns. 
 * It needs to be a JSON-encoded string using the format described in Template Data. 
 * Reserved tokens contain more than one JSON value and can be tricky to add to templateData.
 * 
 * JSON object
 * An object is an unordered set of name/value pairs. An object begins with { (left brace) and ends with } (right brace). 
 * Each name is followed by : (colon) and the name/value pairs are separated by , (comma).
 */
/*
 * Facebook Publish structure 
 */
- (void)publishToFacebook:(NSString*)image_url
{
	FBStreamDialog* dialog = [[FBStreamDialog alloc] init];
	dialog.delegate = self;
	dialog.userMessagePrompt = @"BBCReader";
	NSString *data = nil;
	
	if (image_url) {
		data = [[NSString alloc] initWithFormat:@"{\"caption\": \"%@\", \"description\":\"%@\", \"href\":\"%@\", \"media\":[{\"type\":\"image\",\"src\":\"%@\",\"href\":\"%@\"}]}", 
				(self.webLink.text==nil?@"No title":self.webLink.text), 
				(self.webLink.description ==nil?@"No message":getJASONSafeString(self.webLink.description)), 
				(self.webLink.url ==nil?@"No URL is available":self.webLink.url),
				image_url, self.webLink.url];
		
	}
	else {
		data = [[NSString alloc] initWithFormat:@"{\"caption\": \"%@\", \"description\":\"%@\", \"href\":\"%@\"}", 
				(self.webLink.text==nil?@"No title":self.webLink.text), 
				(self.webLink.description ==nil?@"No message":getJASONSafeString(self.webLink.description)), 
				(self.webLink.url ==nil?@"No URL is available":self.webLink.url)];
	}
	
	TRACE("%s, %s", __func__, [data UTF8String]);
	_fbCallType = FB_UPLOAD_STORY;
	dialog.attachment = data;
	[dialog show];		
	[data release];
	[dialog release];
}

- (FBRequest*)getRequest
{
	return [FBRequest requestWithDelegate:self];
}

- (void)publishPhotoToFacebook
{
	if (self.imageForLink) {
		FBRequest *uploadPhotoRequest = [self getRequest];
		 
		_fbCallType = FB_UPLOAD_PICTURE;
		NSDictionary *params = nil;

		[uploadPhotoRequest call:@"facebook.photos.upload" params:params dataParam:(NSData*)self.imageForLink];
	}
	else {
		NSLog(@"%s, image is not available.", __func__);
		[self publishToFacebook:nil];
	}
}

- (void)performDismiss:(NSTimer*)timer 
{
	[self._alertView dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)showProgress
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Publish" message:@"Syncing with Facebook. Please wait..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	self._alertView = alert;
	[alert release];
	[NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(performDismiss:) userInfo:nil repeats:NO];
	[alert show];
}

- (void)loginToFacebookWithNotification:(BOOL)notify
{
	_notifySuccess = notify;

	FBLoginDialog* dialog = [[FBLoginDialog alloc] initWithSession:[GeoSession getFBSession:self]];
	_fbCallType = FB_REQUEST_LOGIN;
	[dialog show];
	[dialog release];	
}

- (void)publishToFacebookForWebLink:(WebLink*)w
{
	TRACE_HERE;
	
	self.webLink = w;
	self.imageForLink = [[UIImage alloc] initWithContentsOfFile:getActualPath(w.imageLink)];
	
	TRACE("%s, image size: w: %f, h: %f\n", __func__, self.imageForLink.size.width, self.imageForLink.size.height);
	if ([GeoSession sharedGeoSessionInstance].fbUID == 0) {
		[self loginToFacebookWithNotification:NO];
	}
	else if ([GeoSession sharedGeoSessionInstance].gotExtendedPermission == NO) {
		_fbCallType = FB_REQUEST_PERMISSION;
		[[GeoSession sharedGeoSessionInstance] getExtendedPermission:self];
		//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:NO];
	} 
	else {
		[self showProgress];
		[self publishPhotoToFacebook];
	}
	
}

#pragma mark FBSession delegate
- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	NSLog(@"%s, user with id %lld logged in.", __func__, uid);
	[GeoSession sharedGeoSessionInstance].fbUID = uid;
	//[self getUserName];
	
	if (_fbCallType == FB_REQUEST_LOGIN) {
		//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBUserName:) withObject:nil waitUntilDone:NO];	
		_fbCallType = FB_REQUEST_PERMISSION;
		[[GeoSession sharedGeoSessionInstance] getExtendedPermission:self];
		//[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(getFBExtendedPermission:) withObject:self waitUntilDone:YES];
		// Wait for the permission is granted.
	}
}
#pragma mark -
#pragma mark FBRequest delegate

- (void)request:(FBRequest*)request didLoad:(id)result 
{
	TRACE("%s, %s, call: %d, request succeeded. %d\n", __func__, [request.method UTF8String], _fbCallType, result);
	
	if (_fbCallType == FB_UPLOAD_PICTURE) {
		NSDictionary* users = result;
		
		NSString* url = [users objectForKey:@"src"];
		NSString* url_small = [users objectForKey:@"src_small"];
		// Show user name
		
		TRACE("%s, src: %s, src_small: %s\n", __func__, [url UTF8String], [url_small UTF8String]);
		NSLog(@"Query returned %@", [GeoSession sharedGeoSessionInstance].fbUserName);
		
		if (url) {
			[self publishToFacebook:url];
		}
	}
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error 
{
	NSLog(@"%s, request failed. %@", __func__, error);
}

#pragma mark -
#pragma mark FBDialog delegate
/* Facebook picture upload.
 http://forum.developers.facebook.com/viewtopic.php?id=30467
 */
- (void)dialogDidSucceed:(FBDialog*)dialog
{
	TRACE_HERE;
	if (_fbCallType == FB_REQUEST_PERMISSION) {
		// has to be abel to differentiate between FB 
		// Permission for uploading picture succeeded, now upload the picture.
		[GeoSession sharedGeoSessionInstance].gotExtendedPermission = YES;
		if (_notifySuccess) {
			// Notify to ConnectView
			[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(notifyLoggedin:) withObject:nil waitUntilDone:NO];	
		}
		else {
			// This is not login request.
			[self publishPhotoToFacebook];
		}
	}
}

- (void)dialogDidCancel:(FBDialog*)dialog
{
	TRACE_HERE;
	if (_fbCallType == FB_REQUEST_LOGIN || _fbCallType == FB_REQUEST_PERMISSION) {
		[[GeoSession sharedGeoSessionInstance] logoutFBSessionWithNotification:YES];
	}
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
{
	TRACE_HERE;
	NSLog(@"%s, %@", __func__, error);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook error" message:[error description]
												   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}
#pragma mark -

- (void)dealloc
{
	[imageForLink release];
	[webLink release];
	[_alertView release];
	[super dealloc];
}

@end
