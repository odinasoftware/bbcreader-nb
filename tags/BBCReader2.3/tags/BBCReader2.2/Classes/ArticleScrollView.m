//
//  ArticleScrollView.m
//  NYTReader
//
//  Created by Jae Han on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ArticleScrollView.h"


@implementation ArticleScrollView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject]; 
	//startTouchPosition = [touch locationInView:self]; 
	NSUInteger numTaps = [touch tapCount];
	
	[super touchesBegan:touches withEvent:event];
	NSLog(@"Touch begin, :%d", numTaps);
}*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	touchesStatus = TOUCHES_BEGAN;
	//NSLog(@"%s", __func__);
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (touchesStatus == TOUCHES_BEGAN)
		touchesStatus = TOUCHES_MOVED;
	
	//NSLog(@"%s", __func__);
	[super touchesMoved:touches withEvent:event];
}

//static NSTimeInterval tabTimeStamp = 0.0;

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	NSNumber *tapCount = nil;
	
	if (touchesStatus == TOUCHES_BEGAN && [touch tapCount] == 2) {
		touchesStatus = TOUCHES_TAB;
		
		//toolBar.hidden = NO;
		//navigationBar.hidden = NO;
		//if (tabTimeStamp > 0.0 && (event.timestamp - tabTimeStamp > 1.0)) {
		tapCount = [[NSNumber alloc] initWithInt:2];
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showImageControls:) withObject:tapCount waitUntilDone:YES];
		[tapCount release];
		//}
		//tabTimeStamp = event.timestamp;
		
	}
	else if (touchesStatus == TOUCHES_BEGAN && [touch tapCount] == 1) {
		tapCount = [[NSNumber alloc] initWithInt:1];
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showImageControls:) withObject:tapCount waitUntilDone:YES];
		[tapCount release];
	}
	else if (touchesStatus == TOUCHES_MOVED) {
		touchesStatus = TOUCHES_DRAG;
	}
	//NSLog(@"%s", __func__);
	[super touchesEnded:touches withEvent:event];
}

- (void)dealloc {
    [super dealloc];
}


@end
