/*
 * Copyright 2012-2013 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "NMSignInViewController.h"
#import "AppDelegate.h"
#import "StackMob.h"
#import "SMDataStore.h"
#import "User.h"

@interface NMSignInViewController ()

@end

@implementation NMSignInViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize client = _client;

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self updateView];
    
    self.client = [self.appDelegate client];
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
    
    self.managedObjectContext = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    self.client = [SMClient defaultClient];
    
    
}

- (void)viewDidUnload
{
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)updateView {
    
    if ([self.client isLoggedIn]) {
        [self.facebookSignBtn setTitle:@"Log out" forState:UIControlStateNormal];
    } else {
        [self.facebookSignBtn setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


- (IBAction)login:(id)sender {
    [self.client loginWithUsername:self.usernameField.text password:self.passwordField.text onSuccess:^(NSDictionary *results) {
        
        NSLog(@"Login Success %@",results);
        
        /* Uncomment the following if you are using Core Data integration and want to retrieve a managed object representation of the user object.  Store the resulting object or object ID for future use.
         
         Be sure to declare variables you are referencing in this block with the __block storage type modifier, including the managedObjectContext property.
         */
        
        /* // Edit entity name and predicate if you are not using the default user schema with username primary key field.
         NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
         [userFetch setPredicate:[NSPredicate predicateWithFormat:@"username == %@", [results objectForKey:@"username"]]];
         [self.managedObjectContext executeFetchRequest:userFetch onSuccess:^(NSArray *results) {
         NSManagedObject *userObject = [results lastObject];
         // Store userObject somewhere for later use
         NSLog(@"Fetched user object: %@", userObject);
         } onFailure:^(NSError *error) {
         NSLog(@"Error fetching user object: %@", error);
         }];*/
         
        
    } onFailure:^(NSError *error) {
        NSLog(@"Login Fail: %@",error);
    }];
}
- (IBAction)checkStatus:(id)sender {
    if([self.client isLoggedIn]) {
        
        [self.client getLoggedInUserOnSuccess:^(NSDictionary *result) {
            self.statusLabel.text = [NSString stringWithFormat:@"Hello, %@", [result objectForKey:@"username"]];
        } onFailure:^(NSError *error) {
            NSLog(@"No user found");
        }];
        
    } else {
        self.statusLabel.text = @"Nope, not Logged In";
    }
}

- (IBAction)logout:(id)sender {
    [self.client logoutOnSuccess:^(NSDictionary *result) {
        NSLog(@"Success, you are logged out");
    } onFailure:^(NSError *error) {
        NSLog(@"Logout Fail: %@",error);
    }];
}
- (IBAction)btnClickHandler:(id)sender {
    if ([self.client isLoggedIn]) {
        [self logoutUser];
    } else {
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
}
- (void)loginUserWithFacebook {
    
    /*
     Initiate a request for the current Facebook session user info, and apply the username to
     the StackMob user that might be created if one doesn't already exist.  Then login to StackMob with Facebook credentials.
     */
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection,
       NSDictionary<FBGraphUser> *user,
       NSError *error) {
         if (!error) {
             [self.client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken createUserIfNeeded:YES usernameForCreate:user.username onSuccess:^(NSDictionary *result) {
                 NSLog(@"Logged in with StackMob");
                 NSLog(@"%@", user.first_name);
                 NSLog(@"%@", user.last_name);
                 
                 NSDictionary *updatedNewUser = [NSDictionary dictionaryWithObjectsAndKeys:user.first_name, @"firstname", user.last_name, @"lastname", nil];
                 [[self.client dataStore] updateObjectWithId:user.username inSchema:@"user" update:updatedNewUser onSuccess:^(NSDictionary *object, NSString *schema) {
                     // object contains the full updated object.
                 } onFailure:^(NSError *error, NSDictionary* object, NSString *schema) {
                     // Handle error
                 }];

                 
                 [self updateView];
             } onFailure:^(NSError *error) {
                 NSLog(@"Error: %@", error);
             }];
         } else {
             // Handle error accordingly
             NSLog(@"Error getting current Facebook user data, %@", error);
         }
         
     }];
}

- (void)logoutUser {
    
    [self.client logoutOnSuccess:^(NSDictionary *result) {
        NSLog(@"Logged out of StackMob");
        [FBSession.activeSession closeAndClearTokenInformation];
    } onFailure:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            [self loginUserWithFacebook];
            break;
        case FBSessionStateClosed:
            [FBSession.activeSession closeAndClearTokenInformation];
            [self updateView];
            break;
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

@end
