//
//  EmbeddedObjects.h
//  NYTReader
//
//  Created by Jae Han on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface embedded_object_t : NSObject {
	NSString *orig_url;
	NSString *local_name;
	NSString *index_name;
	BOOL	 collision;
} 

@property (nonatomic, retain) NSString* orig_url;
@property (nonatomic, retain) NSString* local_name;
@property (nonatomic, retain) NSString* index_name;
@property (nonatomic, assign) BOOL collision;

@end

@class WebCacheService;

@interface EmbeddedObjects : NSObject {
	NSMutableArray *embeddedObjects;
	NSString *rootName;
	WebCacheService *cacheService;
}

- (void)addEmbeddedObject:(NSString*)orig_url withLocalName:(NSString*)local_name withIndexName:(NSString*)index_name wasCollided:(BOOL)collision;
- (void)saveToStorage;
- (void)moveTheCurrentEmbeddedObjectToFront;

@end
