//
//  NMSignUpViewController.m
//  NetMove
//
//  Created by arthur magne on 02/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//
#import "AppDelegate.h"
#import "StackMob.h"
#import "User.h"
#import "NMSignUpViewController.h"

@interface NMSignUpViewController ()

@end

@implementation NMSignUpViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize usernameField = _usernameField;
@synthesize testField = _testField;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.managedObjectContext = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    self.testField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)createUser:(id)sender {
    
    User *newUser = [[User alloc] initIntoManagedObjectContext:self.managedObjectContext];
    
    [newUser setValue:self.usernameField.text forKey:[newUser primaryKeyField]];
    [newUser setPassword:self.passwordField.text];
    [newUser setValue:self.testField.text forKey:@"test"];
    //[newUser setValue:self.ageField forKey:@"age"];
    
    [self.managedObjectContext saveOnSuccess:^{
        
        NSLog(@"You created a new user object!");
        [[self navigationController] popViewControllerAnimated:YES];
        
    } onFailure:^(NSError *error) {
        
        [self.managedObjectContext deleteObject:newUser];
        [newUser removePassword];
        NSLog(@"There was an error! %@", error);
        
    }];
    
}

@end
