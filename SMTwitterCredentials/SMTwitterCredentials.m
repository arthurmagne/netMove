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

#import "SMTwitterCredentials.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "SMClient.h"
#import "SMError.h"
#import "OAuthCore/OAuthCore.h"

typedef void(^SMTwitterLoginBlock)(NSData *, NSError *);
typedef void(^SMTwitterAuthResponseBlock)(NSDictionary *, NSError *);

@interface SMTwitterCredentials()<UIActionSheetDelegate>
@property (strong, nonatomic) NSString          *twitterConsumerKey;
@property (strong, nonatomic) NSString          *twitterConsumerSecret;
@property (strong, nonatomic) ACAccountStore    *accountStore;
@property (strong, nonatomic) ACAccountType     *accountType;
@property (strong, nonatomic) ACAccount         *twitterAccount;
@property (strong, nonatomic) NSArray           *twitterAccounts;
@property (copy, nonatomic) SMSuccessBlock      successBlock;
@property (copy, nonatomic) SMFailureBlock      failureBlock;
@property (strong, nonatomic) UIActionSheet     *actionSheet;


- (NSURLRequest *)twitterRequestForURL:(NSURL *)url method:(NSString *)method params:(NSDictionary *)params token:(NSString *)token secret:(NSString *)secret;
- (void)requestReverseAuthOnComplete:(SMTwitterAuthResponseBlock)callback;
- (void)requestTwitterAuthorizationWithSignature:(NSString *)signature callback:(SMTwitterAuthResponseBlock)callback;
- (void)sendTwitterSignedAuthorization:(SMTwitterLoginBlock)callback;
@end

@implementation SMTwitterCredentials
static NSString *const SMTwitterURLString           = @"https://api.twitter.com";
static NSString *const SMTwitterAuthModeKey         = @"x_auth_mode";
static NSString *const SMTwitterClientAuth          = @"client_auth";
static NSString *const SMTwitterReverseParams       = @"x_reverse_auth_parameters";
static NSString *const SMTwitterReverseTarget       = @"x_reverse_auth_target";
static NSString *const SMTwitterRequestTokenPath    = @"oauth/request_token";
static NSString *const SMTwitterAuthTokenPath       = @"oauth/access_token";

static NSString *SMDictionaryToQueryString(NSDictionary *dictionary)
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [array addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    
    return [array componentsJoinedByString:@"&"];
}

- (instancetype)initWithTwitterConsumerKey:(NSString *)key secret:(NSString *)secret
{
    self = [super init];
    if (self)
    {
        NSParameterAssert(key);
        NSParameterAssert(secret);
        
        self.accountStore           = [[ACAccountStore alloc] init];
        self.accountType            = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [self setTwitterConsumerKey:key secret:secret];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(refreshTwitterAccounts:)
         name:ACAccountStoreDidChangeNotification
         object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:ACAccountStoreDidChangeNotification
     object:nil];
}

- (void)setTwitterConsumerKey:(NSString *)key secret:(NSString *)secret
{
    self.twitterConsumerKey     = [key copy];
    self.twitterConsumerSecret  = [secret copy];
}

- (void)retrieveTwitterCredentialsForAccount:(NSString *)username onSuccess:(void (^)(NSString *token, NSString *secret, NSDictionary *fullResponse))successBlock onFailure:(SMFailureBlock)failureBlock
{
    if (!self.twitterConsumerKey || !self.twitterConsumerSecret) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:@"Error" code:SMErrorInvalidArguments userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Consumer Key or Secret have not been set.", NSLocalizedDescriptionKey, nil]];
            failureBlock(error);
        }
        return;
    }
    
    self.successBlock       = successBlock;
    self.failureBlock       = failureBlock;
    
    self.twitterAccount = nil;
    
    [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
        if(error || !granted) {
            NSLog(@"You were not granted Access to the Twitter Accounts");
            if (self.failureBlock) {
                self.failureBlock(error);
            }
            return;
        }
        
        self.twitterAccounts = self.accountStore.accounts;
        
        if (username) {
            
            [self.twitterAccounts enumerateObjectsUsingBlock:^(ACAccount *account, NSUInteger idx, BOOL *stop) {
                if ([account.username isEqualToString:username]) {
                    self.twitterAccount = account;
                    *stop = YES;
                }
            }];
            
            if (!self.twitterAccount) {
                if (self.failureBlock) {
                    NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Twitter account for username %@ not found", username], NSLocalizedDescriptionKey, nil]];
                    failureBlock(error);
                }
                return;
            }
            
            [self requestReverseAuthOnComplete:^(NSDictionary *response, NSError *error) {
                
                if (error) {
                    if (self.failureBlock) {
                        self.failureBlock(error);
                    }
                } else if (self.successBlock) {
                    self.successBlock(response[@"oauth_token"], response[@"oauth_token_secret"],response);
                }
                
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                
                [self.twitterAccounts enumerateObjectsUsingBlock:^(ACAccount *account, NSUInteger idx, BOOL *stop) {
                    [self.actionSheet addButtonWithTitle:account.username];
                }];
                
                self.actionSheet.cancelButtonIndex = [self.actionSheet addButtonWithTitle:@"Cancel"];
                
                UIWindow *window = [[UIApplication sharedApplication] keyWindow];
                [self.actionSheet showInView:window.rootViewController.view];
            });
        }
    }];
}

- (void)refreshTwitterAccounts:(id)sender
{
    [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
        if(error || !granted) {
            NSLog(@"You were not granted Access to the Twitter Accounts");
            return;
        }
        
        self.twitterAccounts = self.accountStore.accounts;
        
    }];
}

#pragma mark Internal

- (BOOL)twitterAccountsAvailable
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)requestReverseAuthOnComplete:(SMTwitterAuthResponseBlock)callback
{
    [self sendTwitterSignedAuthorization:^(NSData *data, NSError *error) {
        if(error)
        {
            callback(nil, error);
        }
        else
        {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            [self requestTwitterAuthorizationWithSignature:string callback:^(NSDictionary *result, NSError *error) {
                if(error)
                {
                    callback(nil, error);
                }
                else
                {
                    callback(result, nil);
                }
            }];
        }
    }];
}

- (void)requestTwitterAuthorizationWithSignature:(NSString *)signature callback:(SMTwitterAuthResponseBlock)callback
{
    NSParameterAssert(signature);

    NSDictionary *params        = @{SMTwitterReverseTarget: self.twitterConsumerKey, SMTwitterReverseParams: signature};
    NSString *urlString         = [NSString stringWithFormat:@"%@/%@", SMTwitterURLString, SMTwitterAuthTokenPath];
    NSURL *url                  = [NSURL URLWithString:urlString];
    SLRequest *request          = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:params];
    
    [request setAccount:self.twitterAccount];
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if(error)
        {
            callback(nil, error);
        }
        else
        {
            NSString *res               = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
            NSArray *components         = [res componentsSeparatedByString:@"&"];
            [components enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
                NSArray *parts = [component componentsSeparatedByString:@"="];
                result[parts[0]] = parts[1];
            }];
            
            callback([result copy], nil);
        }
    }]; 
}

- (void)sendTwitterSignedAuthorization:(SMTwitterLoginBlock)callback
{
    NSDictionary *params    = @{SMTwitterAuthModeKey: @"reverse_auth"};
    NSString *urlString     = [NSString stringWithFormat:@"%@/%@", SMTwitterURLString, SMTwitterRequestTokenPath];
    NSURL *url              = [NSURL URLWithString:urlString];
    NSURLRequest *request   = [self twitterRequestForURL:url method:@"post" params:params token:nil secret:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLResponse *response = nil;
        NSError *error          = nil;
        NSData *result          = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            callback(result, error);
        });
    });
}

- (NSURLRequest *)twitterRequestForURL:(NSURL *)url method:(NSString *)method params:(NSDictionary *)params token:(NSString *)token secret:(NSString *)secret
{
    NSString *queryString           = SMDictionaryToQueryString(params);
    NSData *queryData               = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authHeader            = OAuthorizationHeader(url, [method uppercaseString], queryData, self.twitterConsumerKey, self.twitterConsumerSecret, token, secret);
    NSMutableURLRequest *request    = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval         = 10.0;
    request.HTTPMethod              = [method uppercaseString];
    request.HTTPBody                = queryData;
    
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    return request;
}

#pragma mark - UIActionSheet Delegate -
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == actionSheet.cancelButtonIndex)
        return;

    self.twitterAccount = self.twitterAccounts[buttonIndex];
    
    [self requestReverseAuthOnComplete:^(NSDictionary *response, NSError *error) {
        
        if (error) {
            if (self.failureBlock) {
                self.failureBlock(error);
            }
        } else if (self.successBlock) {
            self.successBlock(response[@"oauth_token"], response[@"oauth_token_secret"],response);
        }
        
    }];
}

@end
