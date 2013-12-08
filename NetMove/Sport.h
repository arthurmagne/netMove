//
//  Sport.h
//  NetMove
//
//  Created by arthur magne on 07/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Sport : NSManagedObject

@property (nonatomic, retain) NSString * sport_name;
@property (nonatomic, retain) NSString * sport_id;

@end
