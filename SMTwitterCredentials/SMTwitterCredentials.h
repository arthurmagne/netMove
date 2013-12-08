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

//
//  Created by Wess Cope on 7/30/13.
//  Copyright (c) 2013 Wess Cope. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

typedef ACAccount *(^TwitterAccountsSelectBlock)(NSArray *);

/**
 SMTwitterCredentials is a class for allowing users to log in to a Stackmob based app with their twitter account.
 
 Proper use of this class requires the following:
 
 * Social, Twitter and Accounts frameworks.
 * A project running iOS 6.0+
 * Retrieving Twitter credentials is done using the accounts set up on the device, accessible via Settings -> Twitter. Use the twitterAccountsAvailable methods to check if the user has set up at least one account.
 
 
 ## Example Usage:
 
 // This assumes you have already created your SMClient instance.
 // Declare an SMTwitterCredentials property or the instance will be deallocated before the action sheet returns.
 self.twitterCredentials = [[SMTwitterCredentials alloc] initWithTwitterConsumerKey:@"APP_KEY" secret:@"SECRET_KEY"];
 
 if ([self.twitterCredentials twitterAccountsAvailable]) {
    
    // Passing nil for username will cause an action sheet to pop up showing the user all the available accounts.
    [self.twitterCredentials retrieveTwitterCredentialsForAccount:nil onSuccess:^(NSString *token, NSString *secret, NSDictionary *fullResponse) {
    
        // Save the username if needed via fullResponse[@"screen_name"]
        // Login to StackMob using Twitter credentials
        [[SMClient defaultClient] loginWithTwitterToken:token twitterSecret:secret createUserIfNeeded:YES usernameForCreate:fullResponse[@"screen_name"] onSuccess:^(NSDictionary *result) {
            // result contains the logged in StackMob user object
        } onFailure:^(NSError *error) {
            // Handle error
        }];
 
    } onFailure:^(NSError *error) {
        // Handle Twitter Auth error
    }];
 }
 
 
 */
@interface SMTwitterCredentials : NSObject

/**
 Returns whether or not the Twitter service is accessible and at least one account is set up on the device.
 
 This can be used to check whether the user has set up their Twitter account on their device, which is necessary to use the retrieveTwitterCredentials... method above.
 
 @note The simulator tends to always return true for this method.
 
 */
@property (nonatomic, readonly) twitterAccountsAvailable;

/**
 Instantiates an instance of the SMTwitterCredentials class.
 
 @param key Twitter application key
 @param secret Twitter application secret.
 
 @return SMTwitterCredentials instance.
 */
- (instancetype)initWithTwitterConsumerKey:(NSString *)key secret:(NSString *)secret;

/**
 Sets the Twitter application key and secret for an instance of SMTwitterCredentials.
 
 @param key Twitter application key.
 @param secret Twitter application secret.
 */
- (void)setTwitterConsumerKey:(NSString *)key secret:(NSString *)secret;

/**
 Retrieves the Twitter credentials which can be passed to StackMob's Twitter Authentication methods, found in the SMClient class.
 
 Within the success block, you will most likely login to StackMob using the the SMClient loginWithTwitterToken:twitterSecret:createUserIfNeeded:userNameForCreate:onSuccess:onFailure: method.
 
 To avoid presenting the action sheet upon each app launch, store the value of fullResponse[@"screen_name"] (in NSUserDefaults, for example) and pass it to the username parameter on future login calls. This directs the API to search for an account with that username without user interaction, simulating a "stay logged in" feature.
 
 @note Pass nil for the username parameter to present an action sheet to the user will all available Twitter accounts.
 
 @param username An optional username of an existing Twitter account set up on the user's device.
 @param successBlock A success callback which returns the token, secret, and full response dictionary from the Twitter authorization methods. The full response dictionary includes other keys like screen_name and user_id, which can be used in the future to pass to the username parameter.
 @param failureBlock A failure callback which passes the error.
 
 */
- (void)retrieveTwitterCredentialsForAccount:(NSString *)username onSuccess:(void (^)(NSString *token, NSString *secret, NSDictionary *fullResponse))successBlock onFailure:(void (^)(NSError *error))failureBlock;

@end
