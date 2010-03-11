//
//  SectionSetting.h
//  BBCReader
//
//  Created by Jae Han on 1/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SectionSetting : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource> {
	IBOutlet UIPickerView		*secionPicker;
	IBOutlet UILabel			*manual;
	IBOutlet UISegmentedControl	*segmentedControl;

	@private
	NSInteger selectedFeed;
	NSInteger selectedSegment;
	NSInteger segmentIndexes[3];
}

- (IBAction)toggleSelection:(id)sender;
- (void)cancelAction:(id)sender;
- (void)doneAction:(id)sender;

@end
