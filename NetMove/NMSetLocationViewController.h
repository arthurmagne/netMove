//
//  NMSetLocationViewController.h
//  NetMove
//
//  Created by arthur magne on 14/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>

@interface NMSetLocationViewController : UIViewController <MKMapViewDelegate>

@property NSString* userId;


- (IBAction)getCurrentLocation:(id)sender;
- (IBAction)getLocationWithAdress:(id)sender;
- (IBAction)updateUserLocation:(id)sender;


@end
