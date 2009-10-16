//
//  HeaderFieldValue.h
//  NYTReader
//
//  Created by Jae Han on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {VALUE_NONE, VALUE_ASSIGNED} header_value_t; 

@interface HeaderFieldValue : NSObject {
	NSString *value;
	NSString *excludeString;
	header_value_t status;
	BOOL excludeField;
	BOOL isThisCookie;
}

@property (nonatomic, retain) NSString* value;

- (id)initWithExcludeString:(NSString*)exclude;
- (id)initWithExcludeField:(BOOL)exclude;
- (id)initWithExcludeField:(BOOL)exclude isThisCookie:(BOOL)cookie;
- (BOOL)fillValue:(NSString*)v;
- (NSString*)getValue;
- (void)reset;
- (BOOL)isThisCookie;

@end
