//
//  ThumbNailHolder.h
//  NYTReader
//
//  Created by Jae Han on 8/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface thumb_nail_object_t : NSObject {
	NSString		*orig_url;
	NSString		*local_name;
	NSIndexPath		*indexPath;
} 

@property (nonatomic, retain) NSString* orig_url;
@property (nonatomic, retain) NSString* local_name;
@property (nonatomic, retain) NSIndexPath* indexPath;

@end

@interface ThumbNailHolder : NSObject {
	@private
	NSMutableArray	*theThumbnailHolder;
	int		theCurrentIndex;
}

@property (nonatomic, retain) NSMutableArray *theThumbnailHolder;
@property (nonatomic, assign) NSInteger theCurrentIndex;

+(ThumbNailHolder*) sharedThumbNailHolderInstance;
+ (NSInteger)addThumbnail:(NSString*)orig_url withLocalName:(NSString*)local_name atIndexPath:(NSIndexPath*)indexPath;
+ (void)addThumbnail:(NSString*)orig_url withLocalName:(NSString*)local_name atIndexPath:(NSIndexPath*)indexPath withPrevIndex:(NSInteger)prev;
+ (thumb_nail_object_t*)getThumbnail;
+ (void)releaseThumbNails;

@end
