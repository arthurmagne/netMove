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

#import <UIKit/UIKit.h>
#import "SMTwitterCredentials.h"


@class SMClient;

@interface NMSignInViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *errorMsg;

@property (weak, nonatomic) IBOutlet UIButton *facebookSignBtn;
@property (nonatomic, strong) SMTwitterCredentials *twitterCredentials;
@property (strong, nonatomic) SMClient *client;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;



- (IBAction)btnClickHandlerFacebook:(id)sender;

- (IBAction)btnClickHandlerTwitter:(id)sender;

- (IBAction)login:(id)sender;

- (IBAction)checkStatus:(id)sender;

- (IBAction)logout:(id)sender;

- (IBAction)signUpBtn:(id)sender;


@end
