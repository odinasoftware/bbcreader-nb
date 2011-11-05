//
//  BBCDefaults.m
//  BBCReader
//
//  Created by Jae Han on 11/4/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "BBCDefaults.h"

#define kAccessToken        @"FBAccessTokenKey"
#define kExpirationDate     @"FBExpirationDateKey"

static BBCDefaults  *sharedBBCDefaults = nil;

@implementation BBCDefaults

@synthesize accessToken;
@synthesize expirationDate;

+ (BBCDefaults*)sharedBBCDefaultsInstance
{
    if (sharedBBCDefaults == nil) {
        [[self alloc] init];
    }
    
    return sharedBBCDefaults;
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized (self) { 
		if (sharedBBCDefaults == nil) { 
			sharedBBCDefaults = [super allocWithZone:zone]; 
			return sharedBBCDefaults;
		} 
	} 
	return nil; //on subsequent allocation attempts return nil 
}

-(id)init 
{
	self = [super init];
	if (self) {
		[self initDefaultSettings];
	}
	
	return self;
}

- (void)dealloc
{
    [accessToken release];
    [expirationDate release];
    
    [super dealloc];
}

-(void)initDefaultSettings
{
	srandom(time(NULL));
	NSDictionary *appDefaults = nil;
	
	self.accessToken = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken];
	if (self.accessToken == nil) {
		
		accessToken = [[NSString alloc] init];
        expirationDate = [[NSDate alloc] init];
		
	}
	else {
        self.accessToken = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken];
        self.expirationDate = (NSDate*) [[NSUserDefaults standardUserDefaults] objectForKey:kExpirationDate];
	}
	
	appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
				   accessToken, kAccessToken,
				   expirationDate, kExpirationDate,
				   nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
        
}

- (void)fbSynchronize 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.accessToken forKey:kAccessToken];
    [defaults setObject:self.expirationDate forKey:kExpirationDate];
    [defaults synchronize];

}

@end
