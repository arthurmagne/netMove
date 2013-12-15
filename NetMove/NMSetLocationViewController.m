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

@interface NMSetLocationViewController ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation NMSetLocationViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize userId = _userId;


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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
