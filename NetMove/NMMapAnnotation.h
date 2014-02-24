//
//  NMMapAnnotation.h
//  NetMove
//
//  Created by arthur magne on 15/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface NMMapAnnotation : NSObject <MKAnnotation>{
      CLLocationCoordinate2D coordinate;
}

@property (nonatomic, assign)CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)location;


@end
