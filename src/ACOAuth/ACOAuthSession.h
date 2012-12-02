//
//  ACOAuthSession.h
//  ACOAuth
//
//  Created by Jason Kichline on 7/28/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

extern NSString* const ACOAuthSessionRequestTokenReceived;
extern NSString* const ACOAuthSessionAccessTokenReceived;
extern NSString* const ACOAuthSessionAuthorizationVerified;
extern NSString* const ACOAuthSessionAuthorizationCanceled;

#import <Foundation/Foundation.h>
#import "ACKeychain.h"
#import "ACOAuthConfiguration.h"
#import "ACHTTPRequestModifier.h"

@interface ACOAuthSession : NSObject <ACHTTPRequestModifier> {
	NSMutableData* receivedData;
	NSHTTPURLResponse* response;
	ACOAuthConfiguration* configuration;
}

@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) ACOAuthConfiguration* configuration;

-(id)initWithConfiguration:(ACOAuthConfiguration*)configuration;
+(ACOAuthSession*)sessionWithConfiguration:(ACOAuthConfiguration*)configuration;

-(BOOL)requestToken;
-(BOOL)authorize;
-(BOOL)accessToken;

-(void)signRequest:(NSMutableURLRequest*)request;
-(void)signRequest:(NSMutableURLRequest*)request useAuthorizationHeader:(BOOL)useAuthorizationHeader;
-(BOOL)handleAuthorization:(NSURL*)url;

@end
