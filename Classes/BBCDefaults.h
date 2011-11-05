//
//  BBCDefaults.h
//  BBCReader
//
//  Created by Jae Han on 11/4/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBCDefaults : NSObject {
    NSString    *accessToken;
    NSDate      *expirationDate;
}

@property (nonatomic, retain)   NSString    *accessToken;
@property (nonatomic, retain)   NSDate      *expirationDate;

+ (BBCDefaults*)sharedBBCDefaultsInstance;

-(void)initDefaultSettings;
- (void)fbSynchronize ;

@end
