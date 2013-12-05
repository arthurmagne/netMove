//
//  NMSignUpViewController.h
//  NetMove
//
//  Created by arthur magne on 02/12/2013.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMClient;

@interface NMSignUpViewController : UIViewController <UITextFieldDelegate>


@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField * testField;

@property (strong, nonatomic) SMClient *client;


- (IBAction)createUser:(id)sender;

@end
