//
//  HeaderFieldValue.m
//  NYTReader
//
//  Created by Jae Han on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HeaderFieldValue.h"


@implementation HeaderFieldValue

@synthesize value;

- (id)init
{
	if ((self = [super init])) {
		value = nil;
		excludeString = nil;
		status = VALUE_NONE;
		isThisCookie = NO;
		excludeField = NO;
	}
	
	return self;
}

- (id)initWithExcludeString:(NSString*)exclude
{
	if ((self = [super init])) {
		excludeString = exclude;
		value = nil;
		status = VALUE_NONE;
		isThisCookie = NO;
		excludeField = NO;
	}
	return self;
}

- (id)initWithExcludeField:(BOOL)exclude
{
	if ((self = [super init])) {
		excludeString = nil;
		value = nil;
		status = VALUE_NONE;
		excludeField = exclude;
		isThisCookie = NO;
	}
	return self;
}

- (id)initWithExcludeField:(BOOL)exclude isThisCookie:(BOOL)cookie
{
	if ((self = [super init])) {
		excludeString = nil;
		value = nil;
		status = VALUE_NONE;
		excludeField = exclude;
		isThisCookie = cookie;
	}
	return self;
}


- (BOOL)fillValue:(NSString*)v
{
	BOOL ret = YES;

	if (value != nil) 
		[value release];
	
	value = v;
	status = VALUE_ASSIGNED;

	if (excludeField == YES) 
		ret = NO;
	else if (excludeString != nil && [excludeString compare:v options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		// this field should be excluded.
		ret = NO;
	}
	
	return ret;
}

- (BOOL)isThisCookie
{
	return (isThisCookie && status == VALUE_ASSIGNED);
}

- (void)reset 
{
	if (value != nil) {
		[value release]; 
		value = nil;
	}
	status = VALUE_NONE;
}

- (NSString*)getValue
{
	NSString *val = nil;
	if (status == VALUE_ASSIGNED) {
		val = value;
	}
	
	return val;
}

- (void)dealloc
{
	if (value != nil)
		[value release];
	
	[super dealloc];
}

@end
