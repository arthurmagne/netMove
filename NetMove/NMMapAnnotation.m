//
//  NMMapAnnotation.m
//  NetMove
//
//  Created by arthur magne on 15/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import "NMMapAnnotation.h"


@implementation NMMapAnnotation

@synthesize coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)location{
    self = [super init];
    if (self)
    {
        self.coordinate = location;

    }
    
    return self;
}

@end
