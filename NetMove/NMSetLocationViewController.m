//
//  NMSetLocationViewController.m
//  NetMove
//
//  Created by arthur magne on 14/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import "NMSetLocationViewController.h"
#import "StackMob.h"
#import "SMDataStore.h"
#import "AppDelegate.h"
#import "SMLocationManager.h"
#import "NMMapAnnotation.h"
#import "NMNewsFeedTableViewController.h"

@interface NMSetLocationViewController ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property CLLocationCoordinate2D actualCoord;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *streetLabel;
@property (weak, nonatomic) IBOutlet UITextField *CPLabel;
@property (weak, nonatomic) IBOutlet UITextField *cityLabel;

@end

@implementation NMSetLocationViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize userId = _userId;
@synthesize actualCoord;
@synthesize latitudeLabel = _latitudeLabel;
@synthesize longitudeLabel = _longitudeLabel;
@synthesize mapView = _mapView;
@synthesize streetLabel;
@synthesize cityLabel;
@synthesize CPLabel;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.


    self.managedObjectContext = [[self.appDelegate coreDataStore] contextForCurrentThread];
    
    self.streetLabel.delegate = (id)self;
    self.cityLabel.delegate = (id)self;
    self.CPLabel.delegate = (id)self;

    
    
}

- (CLLocationCoordinate2D) geoCodeUsingAddress:(NSString *)address
{
    double latitude = 0, longitude = 0;
    NSString *esc_addr =  [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *req = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@", esc_addr];
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:req] encoding:NSUTF8StringEncoding error:NULL];
    if (result) {
        // we got a result from the server, now parse it
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:@"\"lat\" :" intoString:nil] && [scanner scanString:@"\"lat\" :" intoString:nil]) {
            [scanner scanDouble:&latitude];
            if ([scanner scanUpToString:@"\"lng\" :" intoString:nil] && [scanner scanString:@"\"lng\" :" intoString:nil]) {
                [scanner scanDouble:&longitude];
            }
        }

    }else{
        [self errorMsgAlert:@"Warning" :@"Connection to Google Maps failed"];

    }
    
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    return center;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)getCurrentLocation:(id)sender {
    // remove previous pins
    id userLocation = [self.mapView userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[self.mapView annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    
    [self.mapView removeAnnotations:pins];
    pins = nil;
    NSString* lat = [NSString stringWithFormat:@"Lat: %f", self.mapView.userLocation.coordinate.latitude];
    NSString* lon = [NSString stringWithFormat:@"Lon: %f", self.mapView.userLocation.coordinate.longitude];
    self.latitudeLabel.text = lat;
    self.longitudeLabel.text = lon;
    
    self.actualCoord = self.mapView.userLocation.coordinate;
    NMMapAnnotation *annotation = [[NMMapAnnotation alloc] initWithCoordinate:CLLocationCoordinate2DMake(self.mapView.userLocation.coordinate.latitude, self.mapView.userLocation.coordinate.longitude)];
    [self.mapView addAnnotation:annotation];
   
    [self setCurrentMapFocus:self.mapView.userLocation.coordinate.latitude :self.mapView.userLocation.coordinate.longitude];


}


- (IBAction)getLocationWithAdress:(id)sender {
    // remove previous pins
    id userLocation = [self.mapView userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[self.mapView annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    
    [self.mapView removeAnnotations:pins];
    pins = nil;
    
    if ([self.cityLabel.text length] == 0){
        [self errorMsgAlert:@"Unable to find corresponding address" :@"Please enter a city name."];
        return;
    }
    
    NSString* address = [[NSString alloc] initWithFormat:@"%@ %@ %@",self.streetLabel.text, self.CPLabel.text, self.cityLabel.text];
    NSLog(@"%@",address);
  
    
    CLLocationCoordinate2D location = [self geoCodeUsingAddress:address];
    if ((location.longitude == 0) && (location.latitude == 0))
        return;
    NSLog(@"l'adresse récupérée est %f, %f",location.latitude, location.longitude);
    NSString* lat = [NSString stringWithFormat:@"Lat: %f", location.latitude];
    NSString* lon = [NSString stringWithFormat:@"Lon: %f", location.longitude];
    self.latitudeLabel.text = lat;
    self.longitudeLabel.text = lon;
    
    self.actualCoord = location;
    NMMapAnnotation *annotation = [[NMMapAnnotation alloc] initWithCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)];
    [self.mapView addAnnotation:annotation];
    [self setCurrentMapFocus:location.latitude :location.longitude];
    
}

- (IBAction)updateUserLocation:(id)sender {
    // start listening for updates from the device GPS
    [[[SMLocationManager sharedInstance] locationManager] startUpdatingLocation];
    SMGeoPoint* geoPoint = [SMGeoPoint geoPointWithCoordinate:self.actualCoord];
    
    
    // Update our user with this location
    NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:geoPoint, @"location", nil];
    [[[SMClient defaultClient] dataStore] updateObjectWithId:self.userId inSchema:@"user" update:arguments onSuccess:^(NSDictionary *object, NSString *schema) {
        // object contains the full updated object.
    } onFailure:^(NSError *error, NSDictionary* object, NSString *schema) {
        // Handle error
    }];
    
    // stop listening for updates from the device GPS
    [[[SMLocationManager sharedInstance] locationManager] stopUpdatingLocation];
    NSLog(@"We got the geoPoint");
    
    // switch storyboard
    UIStoryboard *tabBarStoryboard = [UIStoryboard storyboardWithName:@"TabBarStoryboard" bundle:nil];
    UIViewController *initialTabBarVC = [tabBarStoryboard instantiateInitialViewController];
    initialTabBarVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:initialTabBarVC animated:YES completion:nil];
    

}



- (void)setCurrentMapFocus:(double)latitude :(double)longitude{
    float spanX = 0.00725;
    float spanY = 0.00725;
    MKCoordinateRegion region;
    region.center.latitude = latitude;
    region.center.longitude = longitude;
    region.span.latitudeDelta = spanX;
    region.span.longitudeDelta = spanY;
    [self.mapView setRegion:region animated:YES];
}

- (void)errorMsgAlert:(NSString*)title :(NSString*)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}



@end
